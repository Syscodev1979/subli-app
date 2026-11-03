const { setGlobalOptions } = require("firebase-functions/v2");
const { onDocumentWritten, onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const {
  isMinor,
  planConversation,
  assertDirectChat,
  memberKey,
  addParents,
  nameKeywords,
} = require("./conversation-logic");
const { ADULTS_ONLY, ALLOW_GROUP_CHATS } = require("./club-policy");
const { authorPropagationPlan, chunk } = require("./profile-sync");
const {
  DELETED_NAME,
  tokenIsAdmin,
  userRecordIsAdmin,
  memberAuditPlan,
  deletionGuard,
  unlinkPlan,
  withoutMember,
} = require("./admin-identity");

setGlobalOptions({ region: "europe-west3" });
initializeApp();

const db = getFirestore();

function asDate(value) {
  if (!value) return null;
  if (typeof value.toDate === "function") return value.toDate();
  if (value instanceof Date) return value;
  return null;
}

function budapestToday(now = new Date()) {
  const formatted = new Intl.DateTimeFormat("en-CA", {
    timeZone: "Europe/Budapest",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).format(now);
  const [year, month, day] = formatted.split("-").map(Number);
  return new Date(year, month - 1, day);
}

function personFromUser(id, data, today) {
  return {
    id,
    role: data.role,
    birthDate: asDate(data.birthDate),
    parentIds: Array.isArray(data.parentIds) ? data.parentIds : [],
  };
}

function memberFromUser(id, data, today) {
  const person = personFromUser(id, data, today);
  return {
    name: typeof data.name === "string" ? data.name : "",
    photoUrl: typeof data.photoUrl === "string" && data.photoUrl ? data.photoUrl : null,
    role: data.role,
    isMinor: isMinor(person, today),
    parentIds: person.parentIds,
    searchKeywords: nameKeywords(typeof data.name === "string" ? data.name : ""),
    status: "active",
    beltRank: typeof data.beltRank === "string" && data.beltRank ? data.beltRank : null,
    groupIds: Array.isArray(data.groupIds) ? data.groupIds.filter((id) => typeof id === "string") : [],
  };
}

async function assertAdmin(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Bejelentkezés szükséges.");
  }
  if (!tokenIsAdmin(request.auth.token)) {
    throw new HttpsError("permission-denied", "Csak az admin futtathatja.");
  }
  const caller = await db.collection("users").doc(request.auth.uid).get();
  if (!userRecordIsAdmin(caller.data())) {
    throw new HttpsError("permission-denied", "Csak az admin futtathatja.");
  }
}

async function propagateAuthor(uid, plan) {
  const posts = await db.collection("posts").where("authorId", "==", uid).get();
  const comments = await db.collectionGroup("comments").where("authorId", "==", uid).get();
  const docs = [...posts.docs, ...comments.docs];
  for (const group of chunk(docs, 500)) {
    const batch = db.batch();
    for (const doc of group) {
      batch.update(doc.ref, {
        authorName: plan.authorName,
        authorPhotoUrl: plan.authorPhotoUrl,
      });
    }
    await batch.commit();
  }
}

async function activeParents(parentIds, today) {
  const active = [];
  for (const parentId of parentIds) {
    const snap = await db.collection("users").doc(parentId).get();
    if (!snap.exists) continue;
    const data = snap.data();
    if (data.status === "active") active.push(parentId);
  }
  return active;
}

async function loadActiveUser(id, today) {
  const snap = await db.collection("users").doc(id).get();
  if (!snap.exists || snap.data().status !== "active") return null;
  const data = snap.data();
  const person = personFromUser(id, data, today);
  person.parentIds = await activeParents(person.parentIds, today);
  return person;
}

exports.auditMemberChange = onDocumentWritten("users/{uid}", async (event) => {
  const before = event.data?.before?.data() || null;
  const after = event.data?.after?.data() || null;
  const plan = memberAuditPlan(before, after);
  if (!plan || !plan.actorId) return;
  await db.collection("adminLog").add({
    actorId: plan.actorId,
    targetId: event.params.uid,
    action: plan.action,
    before: plan.before,
    after: plan.after,
    createdAt: FieldValue.serverTimestamp(),
  });
});

exports.syncMember = onDocumentWritten("users/{uid}", async (event) => {
  const uid = event.params.uid;
  const today = budapestToday();
  const afterSnap = event.data.after;
  const beforeSnap = event.data.before;
  const after = afterSnap.exists ? afterSnap.data() : null;
  const before = beforeSnap.exists ? beforeSnap.data() : null;
  const memberRef = db.collection("members").doc(uid);

  if (!after || after.status !== "active") {
    await memberRef.delete();
  } else {
    await memberRef.set(memberFromUser(uid, after, today));
  }

  const plan = authorPropagationPlan(before, after);
  if (plan) await propagateAuthor(uid, plan);

  if (ADULTS_ONLY || !ALLOW_GROUP_CHATS) return;
  if (!after || !isMinor(personFromUser(uid, after, today), today)) return;
  const previous = new Set(Array.isArray(before?.parentIds) ? before.parentIds : []);
  const added = (Array.isArray(after.parentIds) ? after.parentIds : []).filter(
    (id) => !previous.has(id),
  );
  const active = await activeParents(added, today);
  if (active.length === 0) return;

  const conversations = await db
    .collection("conversations")
    .where("memberIds", "array-contains", uid)
    .get();
  for (const doc of conversations.docs) {
    const next = addParents(doc.data(), active);
    if (memberKey(next.memberIds) === memberKey(doc.data().memberIds || [])) continue;
    await doc.ref.update({
      memberIds: next.memberIds,
      guardianIds: next.guardianIds,
      hasMinor: next.hasMinor,
      type: next.type,
      updatedAt: FieldValue.serverTimestamp(),
    });
  }
});

exports.startConversation = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Bejelentkezés szükséges.");
  }
  const otherId = request.data?.otherId;
  if (typeof otherId !== "string" || otherId.length === 0 || otherId === request.auth.uid) {
    throw new HttpsError("invalid-argument", "Válassz egy másik tagot.");
  }
  const today = budapestToday();
  const caller = await loadActiveUser(request.auth.uid, today);
  const other = await loadActiveUser(otherId, today);
  if (!caller || !other) {
    throw new HttpsError("not-found", "A tag nem elérhető.");
  }

  const plan = planConversation(caller, other, today, ADULTS_ONLY);
  try {
    assertDirectChat(plan.memberIds, ALLOW_GROUP_CHATS);
  } catch (error) {
    if (error.code === "group-chat-forbidden") {
      throw new HttpsError(
        "failed-precondition",
        "Csoportos beszélgetés nem hozható létre.",
      );
    }
    throw error;
  }
  const key = memberKey(plan.memberIds);
  const existing = await db
    .collection("conversations")
    .where("memberIds", "array-contains", caller.id)
    .get();
  const found = existing.docs.find((doc) => memberKey(doc.data().memberIds || []) === key);
  if (found) return { conversationId: found.id };

  const ref = db.collection("conversations").doc();
  await ref.set({
    memberIds: plan.memberIds,
    type: plan.type,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    lastReadAt: {},
    hasMinor: plan.hasMinor,
    guardianIds: plan.guardianIds,
  });
  return { conversationId: ref.id };
});

exports.onMessageCreated = onDocumentCreated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const data = event.data?.data();
    if (!data || data.deleted === true) return;
    await db.collection("conversations").doc(event.params.conversationId).update({
      lastMessage: {
        text: typeof data.text === "string" ? data.text : "",
        senderId: data.senderId,
        createdAt: data.createdAt || FieldValue.serverTimestamp(),
      },
      updatedAt: data.createdAt || FieldValue.serverTimestamp(),
    });
  },
);

exports.onMessageUpdated = onDocumentUpdated(
  "conversations/{conversationId}/messages/{messageId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    if (!after?.deleted || before?.deleted) return;
    const conversationRef = db.collection("conversations").doc(event.params.conversationId);
    const conversation = await conversationRef.get();
    const last = conversation.data()?.lastMessage;
    if (!last || last.senderId !== after.senderId) return;
    const lastMillis = last.createdAt?.toMillis?.();
    const messageMillis = after.createdAt?.toMillis?.();
    if (lastMillis != null && messageMillis != null && lastMillis !== messageMillis) return;
    await conversationRef.update({ "lastMessage.text": "" });
  },
);

exports.backfillMembers = onCall(async (request) => {
  await assertAdmin(request);
  const today = budapestToday();
  const users = await db.collection("users").where("status", "==", "active").get();
  let count = 0;
  let batch = db.batch();
  let writes = 0;
  for (const doc of users.docs) {
    batch.set(db.collection("members").doc(doc.id), memberFromUser(doc.id, doc.data(), today));
    count += 1;
    writes += 1;
    if (writes === 400) {
      await batch.commit();
      batch = db.batch();
      writes = 0;
    }
  }
  if (writes > 0) await batch.commit();
  return { count };
});

async function commitInChunks(docs, apply) {
  for (const group of chunk(docs, 400)) {
    const batch = db.batch();
    for (const doc of group) apply(batch, doc);
    await batch.commit();
  }
}

exports.deleteMember = onCall(async (request) => {
  await assertAdmin(request);
  const targetId = request.data?.uid;
  if (typeof targetId !== "string" || !targetId) {
    throw new HttpsError("invalid-argument", "Hiányzó tag.");
  }
  const targetRef = db.collection("users").doc(targetId);
  const targetSnap = await targetRef.get();
  const guard = deletionGuard({
    callerId: request.auth.uid,
    targetId,
    target: targetSnap.exists ? targetSnap.data() : null,
  });
  if (!guard.ok) {
    throw new HttpsError(
      guard.reason === "self" || guard.reason === "admin" ? "failed-precondition" : "not-found",
      guard.reason === "self"
        ? "A saját fiók nem törölhető."
        : guard.reason === "admin"
          ? "Az admin fiók nem törölhető."
          : "A tag nem található.",
    );
  }
  const target = targetSnap.data();
  await propagateAuthor(targetId, { authorName: DELETED_NAME, authorPhotoUrl: null });

  const byMember = await db.collection("conversations")
    .where("memberIds", "array-contains", targetId)
    .get();
  const byGuardian = await db.collection("conversations")
    .where("guardianIds", "array-contains", targetId)
    .get();
  const conversations = new Map();
  for (const doc of [...byMember.docs, ...byGuardian.docs]) {
    conversations.set(doc.id, doc);
  }
  await commitInChunks([...conversations.values()], (batch, doc) => {
    const data = doc.data();
    batch.update(doc.ref, {
      memberIds: withoutMember(data.memberIds, targetId),
      guardianIds: withoutMember(data.guardianIds, targetId),
    });
  });

  const links = unlinkPlan(target);
  for (const childId of links.childIds) {
    await db.collection("users").doc(childId).update({
      parentIds: FieldValue.arrayRemove(targetId),
    }).catch(() => {});
  }
  for (const parentId of links.parentIds) {
    await db.collection("users").doc(parentId).update({
      childIds: FieldValue.arrayRemove(targetId),
    }).catch(() => {});
  }

  await db.collection("members").doc(targetId).delete().catch(() => {});
  await targetRef.delete();
  const { getAuth } = require("firebase-admin/auth");
  await getAuth().deleteUser(targetId).catch((error) => {
    if (error?.code !== "auth/user-not-found") throw error;
  });
  const { getStorage } = require("firebase-admin/storage");
  await getStorage().bucket().file(`users/${targetId}/avatar.jpg`).delete({ ignoreNotFound: true }).catch(() => {});
  await db.collection("adminLog").add({
    actorId: request.auth.uid,
    targetId,
    action: "delete",
    targetName: typeof target.name === "string" ? target.name : "",
    createdAt: FieldValue.serverTimestamp(),
  });
  return { deleted: true };
});

exports.deleteGroup = onCall(async (request) => {
  await assertAdmin(request);
  const groupId = request.data?.groupId;
  if (typeof groupId !== "string" || !groupId) {
    throw new HttpsError("invalid-argument", "Hiányzó csoport.");
  }
  const groupRef = db.collection("groups").doc(groupId);
  const group = await groupRef.get();
  if (!group.exists) {
    throw new HttpsError("not-found", "A csoport nem található.");
  }
  const users = await db.collection("users").where("groupIds", "array-contains", groupId).get();
  await commitInChunks(users.docs, (batch, doc) => {
    batch.update(doc.ref, { groupIds: FieldValue.arrayRemove(groupId) });
  });
  await groupRef.delete();
  await db.collection("adminLog").add({
    actorId: request.auth.uid,
    targetId: groupId,
    action: "delete-group",
    targetName: typeof group.data().name === "string" ? group.data().name : "",
    createdAt: FieldValue.serverTimestamp(),
  });
  return { deleted: true };
});
