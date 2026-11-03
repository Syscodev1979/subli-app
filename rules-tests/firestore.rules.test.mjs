import { readFileSync } from "node:fs";
import { after, before, beforeEach, test } from "node:test";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from "@firebase/rules-unit-testing";
import {
  collection,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  orderBy,
  query,
  setDoc,
  updateDoc,
  where,
  Timestamp,
} from "firebase/firestore";
import { deleteObject, getBytes, ref, uploadBytes, uploadString } from "firebase/storage";

const projectId = "demo-subli-test";
const createdAt = Timestamp.fromDate(new Date("2026-01-15T10:00:00Z"));
const birthDate = Timestamp.fromDate(new Date("1990-03-04T00:00:00Z"));
const laterBirthDate = Timestamp.fromDate(new Date("1990-06-01T00:00:00Z"));
const minorBirthDate = Timestamp.fromDate(new Date("2012-03-04T00:00:00Z"));

function userDoc(overrides = {}) {
  return {
    id: "user",
    name: "Teszt Elek",
    email: "teszt@example.com",
    role: "athlete",
    status: "pending",
    birthDate,
    childIds: [],
    parentIds: [],
    childRequests: [],
    createdAt,
    ...overrides,
  };
}

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId,
    firestore: {
      rules: readFileSync(new URL("../firestore.rules", import.meta.url), "utf8"),
    },
    storage: {
      rules: readFileSync(new URL("../storage.rules", import.meta.url), "utf8"),
    },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
  await testEnv.clearStorage();
});

async function seed(documents) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [id, data] of Object.entries(documents)) {
      await setDoc(doc(db, "users", id), data);
    }
  });
}

test("edző nem módosíthatja admin státuszát", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      name: "Edző",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
    admin1: userDoc({
      id: "admin1",
      name: "Admin",
      email: "admin@example.com",
      role: "admin",
      status: "active",
    }),
  });

  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertFails(
    updateDoc(doc(coach.firestore(), "users", "admin1"), {
      status: "rejected",
    }),
  );
});

test("jóváhagyott sportoló nem írhatja át a birthDate-et", async () => {
  await seed({
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      status: "active",
    }),
  });

  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertFails(
    updateDoc(doc(athlete.firestore(), "users", "athlete1"), {
      birthDate: laterBirthDate,
    }),
  );
});

test("pending sportoló javíthatja a birthDate-et", async () => {
  await seed({
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      status: "pending",
    }),
  });

  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertSucceeds(
    updateDoc(doc(athlete.firestore(), "users", "athlete1"), {
      birthDate: laterBirthDate,
    }),
  );
  await assertFails(
    updateDoc(doc(athlete.firestore(), "users", "athlete1"), {
      birthDate: minorBirthDate,
    }),
  );
});

test("ismeretlen mező create-nél elutasítva", async () => {
  const uid = "new-athlete";
  const user = testEnv.authenticatedContext(uid, {
    email: "uj@example.com",
  });
  await assertFails(
    setDoc(
      doc(user.firestore(), "users", uid),
      userDoc({
        id: uid,
        email: "uj@example.com",
        photoUrl: null,
        isAdmin: true,
      }),
    ),
  );
});

test("hiányzó photoUrl mellett a saját név módosítása sikeres", async () => {
  await seed({
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      status: "active",
    }),
  });

  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertSucceeds(
    updateDoc(doc(athlete.firestore(), "users", "athlete1"), {
      name: "Új Név",
    }),
  );
});

test("admin módosíthatja egy edző státuszát", async () => {
  await seed({
    admin1: userDoc({
      id: "admin1",
      email: "admin@example.com",
      role: "admin",
      status: "active",
    }),
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
  });

  const admin = testEnv.authenticatedContext("admin1", {
    email: "info@sarosigyorgy.hu",
    email_verified: true,
  });
  await assertSucceeds(
    updateDoc(doc(admin.firestore(), "users", "coach1"), {
      status: "rejected",
      auditBy: "admin1",
    }),
  );
});

test("edző nem hagyhat jóvá pending tagot", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      status: "pending",
    }),
  });

  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertFails(
    updateDoc(doc(coach.firestore(), "users", "athlete1"), {
      status: "active",
      auditBy: "coach1",
    }),
  );
});

function postDoc(overrides = {}) {
  return {
    authorId: "coach1",
    authorName: "Edző",
    authorPhotoUrl: null,
    text: "Holnap edzés.",
    createdAt,
    updatedAt: createdAt,
    pinned: false,
    category: "post",
    searchKeywords: ["holnap", "edzes"],
    audience: ["all"],
    ...overrides,
  };
}

async function seedDoc(segments, data) {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), ...segments), data);
  });
}

test("sportoló nem posztolhat", async () => {
  await seed({
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      role: "athlete",
      status: "active",
    }),
  });
  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertFails(
    setDoc(
      doc(athlete.firestore(), "posts", "post-1"),
      postDoc({ authorId: "athlete1", authorName: "Sportoló" }),
    ),
  );
});

test("edző a saját nevében posztolhat", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
  });
  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertSucceeds(
    setDoc(doc(coach.firestore(), "posts", "post-1"), postDoc()),
  );
});

test("ismeretlen kategória és túl hosszú keresőlista elutasítva", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
  });
  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertFails(
    setDoc(
      doc(coach.firestore(), "posts", "bad-category"),
      postDoc({ category: "gossip" }),
    ),
  );
  await assertFails(
    setDoc(
      doc(coach.firestore(), "posts", "long-keywords"),
      postDoc({
        searchKeywords: Array.from({ length: 201 }, (_, index) => `szo${index}`),
      }),
    ),
  );
  await assertSucceeds(
    setDoc(
      doc(coach.firestore(), "posts", "training"),
      postDoc({ category: "post", searchKeywords: ["edzes"] }),
    ),
  );
  await assertSucceeds(
    updateDoc(doc(coach.firestore(), "posts", "training"), {
      category: "event",
      text: "Szombati verseny.",
      searchKeywords: ["szombati", "verseny"],
      eventStartsAt: Timestamp.fromDate(new Date("2026-11-01T17:00:00Z")),
    }),
  );
});

test("esemény dátum nélkül elutasítva, dátummal sikerül", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
  });
  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  const posts = coach.firestore();
  await assertFails(
    setDoc(doc(posts, "posts", "event-missing"), postDoc({ category: "event" })),
  );
  await assertSucceeds(
    setDoc(
      doc(posts, "posts", "event-ok"),
      postDoc({
        category: "event",
        eventStartsAt: Timestamp.fromDate(new Date("2026-11-01T17:00:00Z")),
        eventEndsAt: Timestamp.fromDate(new Date("2026-11-01T19:00:00Z")),
      }),
    ),
  );
});

test("más nevében nem lehet pipázni", async () => {
  await seed({
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      role: "athlete",
      status: "active",
    }),
  });
  await seedDoc(["posts", "post-1"], postDoc());
  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertFails(
    setDoc(doc(athlete.firestore(), "posts", "post-1", "checks", "coach1"), {
      userName: "Sportoló",
      createdAt,
    }),
  );
});

test("a saját pipa létrehozható és nem módosítható", async () => {
  await seed({
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      role: "athlete",
      status: "active",
    }),
  });
  await seedDoc(["posts", "post-1"], postDoc());
  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  const check = doc(athlete.firestore(), "posts", "post-1", "checks", "athlete1");
  await assertSucceeds(
    setDoc(check, { userName: "Sportoló", createdAt }),
  );
  await assertFails(updateDoc(check, { userName: "Más név" }));
  await assertSucceeds(deleteDoc(check));
});

test("idegen hozzászólást sportoló nem törölhet", async () => {
  await seed({
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      role: "athlete",
      status: "active",
    }),
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
  });
  await seedDoc(["posts", "post-1"], postDoc());
  await seedDoc(["posts", "post-1", "comments", "comment-1"], {
    authorId: "coach1",
    authorName: "Edző",
    authorPhotoUrl: null,
    text: "Rendben.",
    createdAt,
  });
  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertFails(
    deleteDoc(
      doc(athlete.firestore(), "posts", "post-1", "comments", "comment-1"),
    ),
  );
  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertSucceeds(
    deleteDoc(
      doc(coach.firestore(), "posts", "post-1", "comments", "comment-1"),
    ),
  );
});

test("pending felhasználó nem olvashat bejegyzést", async () => {
  await seed({
    pending1: userDoc({
      id: "pending1",
      email: "pending@example.com",
      role: "athlete",
      status: "pending",
    }),
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      role: "athlete",
      status: "active",
    }),
  });
  await seedDoc(["posts", "post-1"], postDoc());
  const pending = testEnv.authenticatedContext("pending1", {
    email: "pending@example.com",
  });
  await assertFails(getDoc(doc(pending.firestore(), "posts", "post-1")));
  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertSucceeds(getDoc(doc(athlete.firestore(), "posts", "post-1")));
});

test("a szerző nem írhatja át a bejegyzés authorId-ját", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
  });
  await seedDoc(["posts", "post-1"], postDoc());
  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertFails(
    updateDoc(doc(coach.firestore(), "posts", "post-1"), {
      authorId: "athlete1",
    }),
  );
  await assertSucceeds(
    updateDoc(doc(coach.firestore(), "posts", "post-1"), {
      text: "Módosított szöveg.",
    }),
  );
});

test("a szerző és az admin törölheti az idegen pipát", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      role: "athlete",
      status: "active",
    }),
    athlete2: userDoc({
      id: "athlete2",
      name: "Másik Sportoló",
      email: "athlete2@example.com",
      role: "athlete",
      status: "active",
    }),
    admin1: userDoc({
      id: "admin1",
      email: "admin@example.com",
      role: "admin",
      status: "active",
    }),
  });
  await seedDoc(["posts", "post-1"], postDoc());
  await seedDoc(["posts", "post-1", "checks", "athlete1"], {
    userName: "Sportoló",
    createdAt,
  });

  const other = testEnv.authenticatedContext("athlete2", {
    email: "athlete2@example.com",
  });
  await assertFails(
    deleteDoc(doc(other.firestore(), "posts", "post-1", "checks", "athlete1")),
  );

  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertSucceeds(
    deleteDoc(doc(coach.firestore(), "posts", "post-1", "checks", "athlete1")),
  );

  await seedDoc(["posts", "post-1", "checks", "athlete1"], {
    userName: "Sportoló",
    createdAt,
  });
  const admin = testEnv.authenticatedContext("admin1", {
    email: "info@sarosigyorgy.hu",
    email_verified: true,
  });
  await assertSucceeds(
    deleteDoc(doc(admin.firestore(), "posts", "post-1", "checks", "athlete1")),
  );
});

function imageMedia(url = "https://example.com/a.jpg") {
  return {
    type: "image",
    url,
    thumbUrl: null,
    width: 800,
    height: 600,
    durationSec: null,
  };
}

function videoMedia(durationSec = 30) {
  return {
    type: "video",
    url: "https://example.com/a.mp4",
    thumbUrl: "https://example.com/a.jpg",
    width: 1280,
    height: 720,
    durationSec,
  };
}

test("üres szöveggel is posztolható, ha van kép", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
  });
  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertSucceeds(
    setDoc(
      doc(coach.firestore(), "posts", "post-1"),
      postDoc({ text: "", media: [imageMedia()] }),
    ),
  );
});

test("tíz képnél több és két videó elutasítva", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
  });
  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertFails(
    setDoc(
      doc(coach.firestore(), "posts", "too-many"),
      postDoc({
        media: Array.from({ length: 11 }, (_, index) =>
          imageMedia(`https://example.com/${index}.jpg`),
        ),
      }),
    ),
  );
  await assertFails(
    setDoc(
      doc(coach.firestore(), "posts", "two-videos"),
      postDoc({ media: [videoMedia(), videoMedia(20)] }),
    ),
  );
  await assertFails(
    setDoc(
      doc(coach.firestore(), "posts", "long-video"),
      postDoc({ media: [videoMedia(181)] }),
    ),
  );
});

test("sportoló nem tölthet fel, edző igen, a szerző törölheti a fájlt", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      role: "athlete",
      status: "active",
    }),
    athlete2: userDoc({
      id: "athlete2",
      name: "Másik Sportoló",
      email: "athlete2@example.com",
      role: "athlete",
      status: "active",
    }),
    pending1: userDoc({
      id: "pending1",
      email: "pending@example.com",
      role: "athlete",
      status: "pending",
    }),
    admin1: userDoc({
      id: "admin1",
      email: "admin@example.com",
      role: "admin",
      status: "active",
    }),
  });
  await seedDoc(["posts", "post-1"], postDoc());

  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertFails(
    uploadString(ref(athlete.storage(), "posts/post-1/a.jpg"), "img", "raw", {
      contentType: "image/jpeg",
    }),
  );

  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  const file = ref(coach.storage(), "posts/post-1/a.jpg");
  await assertSucceeds(
    uploadString(file, "img", "raw", { contentType: "image/jpeg" }),
  );
  await assertFails(
    uploadString(ref(coach.storage(), "posts/post-1/note.txt"), "x", "raw", {
      contentType: "text/plain",
    }),
  );

  const pending = testEnv.authenticatedContext("pending1", {
    email: "pending@example.com",
  });
  await assertFails(getBytes(ref(pending.storage(), "posts/post-1/a.jpg")));
  await assertSucceeds(getBytes(ref(athlete.storage(), "posts/post-1/a.jpg")));

  const other = testEnv.authenticatedContext("athlete2", {
    email: "athlete2@example.com",
  });
  await assertFails(deleteObject(ref(other.storage(), "posts/post-1/a.jpg")));
  await assertSucceeds(deleteObject(file));

  await assertSucceeds(
    uploadString(ref(coach.storage(), "posts/post-1/b.jpg"), "img", "raw", {
      contentType: "image/jpeg",
    }),
  );
  const admin = testEnv.authenticatedContext("admin1", {
    email: "info@sarosigyorgy.hu",
    email_verified: true,
  });
  await assertSucceeds(
    deleteObject(ref(admin.storage(), "posts/post-1/b.jpg")),
  );
});

test("edző csak a saját vagy még nem létező bejegyzéshez tölthet fel", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
    coach2: userDoc({
      id: "coach2",
      name: "Másik Edző",
      email: "coach2@example.com",
      role: "coach",
      status: "active",
    }),
    admin1: userDoc({
      id: "admin1",
      email: "admin@example.com",
      role: "admin",
      status: "active",
    }),
  });
  await seedDoc(["posts", "post-1"], postDoc({ authorId: "coach1" }));

  const author = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  const file = ref(author.storage(), "posts/post-1/a.jpg");
  await assertSucceeds(
    uploadString(file, "img", "raw", { contentType: "image/jpeg" }),
  );
  await assertSucceeds(
    uploadString(file, "img2", "raw", { contentType: "image/jpeg" }),
  );

  const other = testEnv.authenticatedContext("coach2", {
    email: "coach2@example.com",
  });
  await assertFails(
    uploadString(ref(other.storage(), "posts/post-1/b.jpg"), "img", "raw", {
      contentType: "image/jpeg",
    }),
  );
  await assertFails(
    uploadString(ref(other.storage(), "posts/post-1/a.jpg"), "overwrite", "raw", {
      contentType: "image/jpeg",
    }),
  );

  const admin = testEnv.authenticatedContext("admin1", {
    email: "info@sarosigyorgy.hu",
    email_verified: true,
  });
  await assertSucceeds(
    uploadString(ref(admin.storage(), "posts/post-1/c.jpg"), "img", "raw", {
      contentType: "image/jpeg",
    }),
  );
  await assertSucceeds(
    uploadString(ref(admin.storage(), "posts/post-1/a.jpg"), "admin", "raw", {
      contentType: "image/jpeg",
    }),
  );

  await assertSucceeds(
    uploadString(ref(other.storage(), "posts/new-post/a.jpg"), "img", "raw", {
      contentType: "image/jpeg",
    }),
  );
});

test("nem tag nem olvas üzenetet, és a kliens nem ír taglistát", async () => {
  await seed({
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      role: "athlete",
      status: "active",
    }),
    athlete2: userDoc({
      id: "athlete2",
      name: "Másik Sportoló",
      email: "athlete2@example.com",
      role: "athlete",
      status: "active",
    }),
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, "conversations", "c1"), {
      memberIds: ["athlete1", "coach1"],
      type: "direct",
      createdAt,
      updatedAt: createdAt,
      lastReadAt: {},
      hasMinor: false,
      guardianIds: [],
    });
    await setDoc(doc(db, "conversations", "c1", "messages", "m1"), {
      senderId: "coach1",
      text: "Szia",
      createdAt,
      deleted: false,
    });
    await setDoc(doc(db, "members", "coach1"), {
      name: "Edző",
      photoUrl: null,
      role: "coach",
      isMinor: false,
      parentIds: [],
      searchKeywords: ["edzo"],
      status: "active",
    });
  });

  const outsider = testEnv.authenticatedContext("athlete2", {
    email: "athlete2@example.com",
  });
  await assertFails(
    getDoc(doc(outsider.firestore(), "conversations", "c1", "messages", "m1")),
  );
  await assertFails(
    setDoc(doc(outsider.firestore(), "members", "athlete2"), {
      name: "Másik",
      photoUrl: null,
      role: "athlete",
      isMinor: false,
      parentIds: [],
      searchKeywords: ["masik"],
      status: "active",
    }),
  );

  const member = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertSucceeds(
    getDoc(doc(member.firestore(), "conversations", "c1", "messages", "m1")),
  );
  await assertSucceeds(getDoc(doc(member.firestore(), "members", "coach1")));
  await assertFails(
    setDoc(doc(member.firestore(), "conversations", "c1", "messages", "fake"), {
      senderId: "coach1",
      text: "Más nevében.",
      createdAt,
      deleted: false,
    }),
  );
  await assertSucceeds(
    setDoc(doc(member.firestore(), "conversations", "c1", "messages", "mine"), {
      senderId: "athlete1",
      text: "Ott leszek.",
      createdAt,
      deleted: false,
    }),
  );
  await assertFails(
    updateDoc(doc(member.firestore(), "conversations", "c1"), {
      memberIds: ["athlete1", "athlete2", "coach1"],
    }),
  );
  await assertSucceeds(
    updateDoc(doc(member.firestore(), "conversations", "c1"), {
      "lastReadAt.athlete1": createdAt,
    }),
  );
});

test("csoportos beszélgetés nem hozható létre, a kétszemélyes üzenet igen", async () => {
  await seed({
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      role: "athlete",
      status: "active",
    }),
    athlete2: userDoc({
      id: "athlete2",
      name: "Másik Sportoló",
      email: "athlete2@example.com",
      role: "athlete",
      status: "active",
    }),
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
  });
  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertFails(
    setDoc(doc(coach.firestore(), "conversations", "group"), {
      memberIds: ["coach1", "athlete1", "athlete2"],
      type: "group",
      createdAt,
      updatedAt: createdAt,
      lastReadAt: {},
      hasMinor: false,
      guardianIds: [],
    }),
  );
  await assertFails(
    setDoc(doc(coach.firestore(), "conversations", "pair"), {
      memberIds: ["coach1", "athlete1"],
      type: "direct",
      createdAt,
      updatedAt: createdAt,
      lastReadAt: {},
      hasMinor: false,
      guardianIds: [],
    }),
  );

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "conversations", "pair"), {
      memberIds: ["coach1", "athlete1"],
      type: "direct",
      createdAt,
      updatedAt: createdAt,
      lastReadAt: {},
      hasMinor: false,
      guardianIds: [],
    });
  });
  await assertFails(
    updateDoc(doc(coach.firestore(), "conversations", "pair"), {
      memberIds: ["coach1", "athlete1", "athlete2"],
    }),
  );
  await assertSucceeds(
    setDoc(doc(coach.firestore(), "conversations", "pair", "messages", "m1"), {
      senderId: "coach1",
      text: "Szia",
      createdAt,
      deleted: false,
    }),
  );
});

test("a saját reakció cserélhető, idegenét más sportoló nem törli", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      role: "athlete",
      status: "active",
    }),
    athlete2: userDoc({
      id: "athlete2",
      name: "Másik Sportoló",
      email: "athlete2@example.com",
      role: "athlete",
      status: "active",
    }),
  });
  await seedDoc(["posts", "post-1"], postDoc());
  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  const reaction = doc(
    athlete.firestore(),
    "posts",
    "post-1",
    "reactions",
    "athlete1",
  );
  await assertSucceeds(
    setDoc(reaction, { userName: "Sportoló", type: "like", createdAt }),
  );
  await assertSucceeds(
    updateDoc(reaction, { userName: "Sportoló", type: "horse", createdAt }),
  );
  await assertFails(
    setDoc(doc(athlete.firestore(), "posts", "post-1", "reactions", "athlete2"), {
      userName: "Másik",
      type: "like",
      createdAt,
    }),
  );

  const other = testEnv.authenticatedContext("athlete2", {
    email: "athlete2@example.com",
  });
  await assertFails(
    deleteDoc(
      doc(other.firestore(), "posts", "post-1", "reactions", "athlete1"),
    ),
  );
  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertSucceeds(
    deleteDoc(
      doc(coach.firestore(), "posts", "post-1", "reactions", "athlete1"),
    ),
  );
});

function documentItem(name, mime, sizeBytes) {
  return {
    type: "document",
    url: `https://example.com/${name}`,
    name,
    sizeBytes,
    mimeType: mime,
  };
}

test("sportoló nem írhatja a saját beltRank-ját", async () => {
  await seed({
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      status: "active",
    }),
  });
  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertFails(
    updateDoc(doc(athlete.firestore(), "users", "athlete1"), {
      beltRank: "beginner",
    }),
  );
});

test("szülő a gyereke photoUrl-jét módosíthatja, más mezőjét nem", async () => {
  await seed({
    parent1: userDoc({
      id: "parent1",
      email: "parent@example.com",
      role: "parent",
      status: "active",
      birthDate: null,
      childIds: ["child1"],
    }),
    child1: userDoc({
      id: "child1",
      email: "child@example.com",
      status: "active",
      parentIds: ["parent1"],
    }),
  });
  const parent = testEnv.authenticatedContext("parent1", {
    email: "parent@example.com",
  });
  await assertSucceeds(
    updateDoc(doc(parent.firestore(), "users", "child1"), {
      photoUrl: "https://example.com/avatar.jpg",
    }),
  );
  await assertFails(
    updateDoc(doc(parent.firestore(), "users", "child1"), {
      name: "Más név",
    }),
  );
});

test("idegen nem tölthet fel más profilképét", async () => {
  await seed({
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      status: "active",
    }),
    athlete2: userDoc({
      id: "athlete2",
      email: "athlete2@example.com",
      status: "active",
    }),
  });
  const other = testEnv.authenticatedContext("athlete2", {
    email: "athlete2@example.com",
  });
  await assertFails(
    uploadString(ref(other.storage(), "users/athlete1/avatar.jpg"), "img", "raw", {
      contentType: "image/jpeg",
    }),
  );
  const owner = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertSucceeds(
    uploadString(ref(owner.storage(), "users/athlete1/avatar.jpg"), "img", "raw", {
      contentType: "image/jpeg",
    }),
  );
});

test("edző nem hagyhat jóvá edzőjelentkezést", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
    applicant: userDoc({
      id: "applicant",
      email: "coach-applicant@example.com",
      role: "athlete",
      status: "pending",
      requestedRole: "coach",
    }),
  });
  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertFails(
    updateDoc(doc(coach.firestore(), "users", "applicant"), {
      status: "active",
      role: "coach",
    }),
  );
});

test("18 év alatti regisztráció és a parent szerep elutasítva", async () => {
  const minor = testEnv.authenticatedContext("minor-user", {
    email: "minor@example.com",
  });
  await assertFails(
    setDoc(
      doc(minor.firestore(), "users", "minor-user"),
      userDoc({
        id: "minor-user",
        email: "minor@example.com",
        birthDate: minorBirthDate,
      }),
    ),
  );

  const parent = testEnv.authenticatedContext("parent-user", {
    email: "szulo@example.com",
  });
  await assertFails(
    setDoc(
      doc(parent.firestore(), "users", "parent-user"),
      userDoc({
        id: "parent-user",
        email: "szulo@example.com",
        role: "parent",
        birthDate: null,
      }),
    ),
  );

  const adult = testEnv.authenticatedContext("adult-user", {
    email: "felnott@example.com",
  });
  await assertSucceeds(
    setDoc(
      doc(adult.firestore(), "users", "adult-user"),
      userDoc({
        id: "adult-user",
        email: "felnott@example.com",
        role: "member",
        birthDate,
      }),
    ),
  );
});

test("requestedRole más értékkel elutasítva", async () => {
  const uid = "new-coach";
  const user = testEnv.authenticatedContext(uid, { email: "uj@example.com" });
  await assertFails(
    setDoc(
      doc(user.firestore(), "users", uid),
      userDoc({
        id: uid,
        email: "uj@example.com",
        requestedRole: "admin",
      }),
    ),
  );
  await assertFails(
    setDoc(
      doc(user.firestore(), "users", uid),
      userDoc({
        id: uid,
        email: "uj@example.com",
        role: "member",
        requestedRole: "coach",
      }),
    ),
  );
  await assertFails(
    setDoc(
      doc(user.firestore(), "users", uid),
      userDoc({
        id: uid,
        email: "uj@example.com",
        role: "coach",
      }),
    ),
  );
  await assertSucceeds(
    setDoc(
      doc(user.firestore(), "users", uid),
      userDoc({
        id: uid,
        email: "uj@example.com",
        role: "member",
      }),
    ),
  );
});

test("nem engedélyezett dokumentumtípus és 20 MB feletti dokumentum elutasítva", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
  });
  await seedDoc(["posts", "post-1"], postDoc());
  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertFails(
    uploadString(ref(coach.storage(), "posts/post-1/docs/jegyzet.txt"), "x", "raw", {
      contentType: "text/plain",
    }),
  );
  await assertFails(
    uploadBytes(
      ref(coach.storage(), "posts/post-1/docs/nagy.pdf"),
      new Uint8Array(20 * 1024 * 1024 + 1),
      { contentType: "application/pdf" },
    ),
  );
  await assertSucceeds(
    uploadString(ref(coach.storage(), "posts/post-1/docs/oklevel.pdf"), "%PDF", "raw", {
      contentType: "application/pdf",
    }),
  );
});

test("a hatodik dokumentum elutasítva", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
  });
  await seedDoc(["posts", "post-1"], postDoc());
  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  const documents = [1, 2, 3, 4, 5, 6].map((index) =>
    documentItem(`file-${index}.pdf`, "application/pdf", 1000),
  );
  await assertFails(
    updateDoc(doc(coach.firestore(), "posts", "post-1"), { media: documents }),
  );
  await assertSucceeds(
    updateDoc(doc(coach.firestore(), "posts", "post-1"), {
      media: documents.slice(0, 5),
    }),
  );
});

async function seedAudienceClub() {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      role: "athlete",
      status: "active",
    }),
    parent1: userDoc({
      id: "parent1",
      name: "Szülő",
      email: "parent@example.com",
      role: "parent",
      status: "active",
      birthDate: null,
    }),
  });
}

test("sportoló nem olvashat vezetőségi bejegyzést, hozzászólást, reakciót és fájlt", async () => {
  await seedAudienceClub();
  await seedDoc(
    ["posts", "staff-post"],
    postDoc({ audience: ["staff"], text: "Vezetőségi körlevél." }),
  );
  await seedDoc(["posts", "staff-post", "comments", "c1"], {
    authorId: "coach1",
    authorName: "Edző",
    authorPhotoUrl: null,
    text: "Belső megjegyzés.",
    createdAt,
  });
  await seedDoc(["posts", "staff-post", "reactions", "coach1"], {
    userName: "Edző",
    type: "like",
    createdAt,
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await uploadString(
      ref(context.storage(), "posts/staff-post/a.jpg"),
      "img",
      "raw",
      { contentType: "image/jpeg" },
    );
  });

  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertFails(getDoc(doc(athlete.firestore(), "posts", "staff-post")));
  await assertFails(
    getDoc(doc(athlete.firestore(), "posts", "staff-post", "comments", "c1")),
  );
  await assertFails(
    getDoc(doc(athlete.firestore(), "posts", "staff-post", "reactions", "coach1")),
  );
  await assertFails(
    setDoc(doc(athlete.firestore(), "posts", "staff-post", "comments", "c2"), {
      authorId: "athlete1",
      authorName: "Sportoló",
      authorPhotoUrl: null,
      text: "Nem láthatom.",
      createdAt,
    }),
  );
  await assertFails(getBytes(ref(athlete.storage(), "posts/staff-post/a.jpg")));

  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertSucceeds(getDoc(doc(coach.firestore(), "posts", "staff-post")));
  await assertSucceeds(getBytes(ref(coach.storage(), "posts/staff-post/a.jpg")));
});

test("szülő olvashat szülői bejegyzést, sportoló nem", async () => {
  await seedAudienceClub();
  await seedDoc(
    ["posts", "parent-post"],
    postDoc({ audience: ["parents"], text: "Szülői értekezlet." }),
  );

  const parent = testEnv.authenticatedContext("parent1", {
    email: "parent@example.com",
  });
  await assertSucceeds(getDoc(doc(parent.firestore(), "posts", "parent-post")));

  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertFails(getDoc(doc(athlete.firestore(), "posts", "parent-post")));

  const parentList = await getDocs(
    query(
      collection(parent.firestore(), "posts"),
      where("audience", "array-contains-any", ["all", "parents"]),
      orderBy("pinned", "desc"),
      orderBy("createdAt", "desc"),
    ),
  );
  if (parentList.size !== 1) {
    throw new Error(`a szülő lekérdezése ${parentList.size} bejegyzést adott`);
  }

  const athleteList = await getDocs(
    query(
      collection(athlete.firestore(), "posts"),
      where("audience", "array-contains-any", ["all", "athletes"]),
      orderBy("pinned", "desc"),
      orderBy("createdAt", "desc"),
    ),
  );
  if (athleteList.size !== 0) {
    throw new Error(`a sportoló lekérdezése ${athleteList.size} bejegyzést adott`);
  }
});

test("csak a minden tag célközönség írható, a többi elutasítva", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
  });
  const coach = testEnv.authenticatedContext("coach1", {
    email: "coach@example.com",
  });
  await assertFails(
    setDoc(
      doc(coach.firestore(), "posts", "mixed"),
      postDoc({ audience: ["all", "parents"] }),
    ),
  );
  await assertFails(
    setDoc(doc(coach.firestore(), "posts", "empty"), postDoc({ audience: [] })),
  );
  await assertFails(
    setDoc(
      doc(coach.firestore(), "posts", "both"),
      postDoc({ audience: ["parents", "athletes"] }),
    ),
  );
  await assertFails(
    setDoc(
      doc(coach.firestore(), "posts", "staff-only"),
      postDoc({ audience: ["staff"] }),
    ),
  );
  await assertSucceeds(
    setDoc(
      doc(coach.firestore(), "posts", "everyone"),
      postDoc({ audience: ["all"] }),
    ),
  );
  await assertFails(
    updateDoc(doc(coach.firestore(), "posts", "everyone"), {
      audience: ["staff"],
    }),
  );
});

test("célközönség nélküli régi bejegyzés minden aktív tagnak látszik", async () => {
  await seedAudienceClub();
  const legacy = postDoc({ text: "Régi hír." });
  delete legacy.audience;
  await seedDoc(["posts", "legacy"], legacy);

  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertSucceeds(getDoc(doc(athlete.firestore(), "posts", "legacy")));

  const parent = testEnv.authenticatedContext("parent1", {
    email: "parent@example.com",
  });
  await assertSucceeds(getDoc(doc(parent.firestore(), "posts", "legacy")));
});

const adminToken = { email: "info@sarosigyorgy.hu", email_verified: true };

function groupDoc() {
  return {
    name: "Kezdők",
    color: "#2E7D32",
    description: "Alap csoport",
    createdAt,
  };
}

test("senki nem állíthat be admin szerepet, az admin sem", async () => {
  await seed({
    admin1: userDoc({
      id: "admin1",
      email: "info@sarosigyorgy.hu",
      role: "admin",
      status: "active",
    }),
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      status: "active",
    }),
  });
  const admin = testEnv.authenticatedContext("admin1", adminToken);
  await assertFails(
    updateDoc(doc(admin.firestore(), "users", "athlete1"), {
      role: "admin",
      auditBy: "admin1",
    }),
  );
  await assertFails(
    updateDoc(doc(admin.firestore(), "users", "admin1"), {
      role: "coach",
      auditBy: "admin1",
    }),
  );
  await assertFails(
    updateDoc(doc(admin.firestore(), "users", "admin1"), {
      status: "suspended",
      auditBy: "admin1",
    }),
  );
  await assertFails(
    updateDoc(doc(admin.firestore(), "users", "athlete1"), {
      role: "coach",
      auditBy: "admin1",
    }),
  );
  await assertFails(
    updateDoc(doc(admin.firestore(), "users", "athlete1"), {
      role: "member",
      auditBy: "admin1",
    }),
  );
});

test("csak a kijelölt cím kap admin jogot, a régi helyettesítő nem", async () => {
  await seed({
    admin1: userDoc({
      id: "admin1",
      email: "info@sarosigyorgy.hu",
      role: "admin",
      status: "active",
    }),
  });
  await seedDoc(["posts", "post-1"], postDoc({ authorId: "admin1" }));

  const designated = testEnv.authenticatedContext("admin1", {
    email: "Info@SarosiGyorgy.hu",
    email_verified: true,
  });
  await assertSucceeds(
    setDoc(doc(designated.firestore(), "groups", "g-case"), groupDoc()),
  );
  await assertSucceeds(
    uploadString(ref(designated.storage(), "posts/post-1/admin.jpg"), "img", "raw", {
      contentType: "image/jpeg",
    }),
  );

  const placeholder = testEnv.authenticatedContext("admin1", {
    email: "admin-beallitando@invalid",
    email_verified: true,
  });
  await assertFails(
    setDoc(doc(placeholder.firestore(), "groups", "g-old"), groupDoc()),
  );
  await assertFails(
    uploadString(ref(placeholder.storage(), "posts/post-1/old.jpg"), "img", "raw", {
      contentType: "image/jpeg",
    }),
  );

  const other = testEnv.authenticatedContext("admin1", {
    email: "mas@example.com",
    email_verified: true,
  });
  await assertFails(
    setDoc(doc(other.firestore(), "groups", "g-other"), groupDoc()),
  );
});

test("más e-mail címmel nem lehet admin", async () => {
  await seed({
    fake: userDoc({
      id: "fake",
      email: "mas@example.com",
      role: "admin",
      status: "active",
    }),
  });
  const fake = testEnv.authenticatedContext("fake", {
    email: "mas@example.com",
  });
  await assertFails(setDoc(doc(fake.firestore(), "groups", "g1"), groupDoc()));
  await assertFails(getDoc(doc(fake.firestore(), "adminLog", "missing")));
});

test("edző nem írhat csoportot és nem módosíthat szerepet", async () => {
  await seed({
    coach1: userDoc({
      id: "coach1",
      email: "coach@example.com",
      role: "coach",
      status: "active",
    }),
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      status: "active",
    }),
  });
  const coach = testEnv.authenticatedContext("coach1", { email: "coach@example.com" });
  await assertFails(setDoc(doc(coach.firestore(), "groups", "g1"), groupDoc()));
  await assertFails(
    updateDoc(doc(coach.firestore(), "users", "athlete1"), {
      role: "coach",
      auditBy: "coach1",
    }),
  );
});

test("felfüggesztett tag nem olvas bejegyzést", async () => {
  await seed({
    suspended1: userDoc({
      id: "suspended1",
      email: "stop@example.com",
      status: "suspended",
    }),
  });
  await seedDoc(["posts", "news"], postDoc());
  const suspended = testEnv.authenticatedContext("suspended1", {
    email: "stop@example.com",
  });
  await assertFails(getDoc(doc(suspended.firestore(), "posts", "news")));
  await assertSucceeds(getDoc(doc(suspended.firestore(), "users", "suspended1")));
});

test("adminLog-ot a kliens nem írhat, az admin olvashatja", async () => {
  await seed({
    admin1: userDoc({
      id: "admin1",
      email: "info@sarosigyorgy.hu",
      role: "admin",
      status: "active",
    }),
  });
  await seedDoc(["adminLog", "log1"], {
    actorId: "admin1",
    targetId: "athlete1",
    action: "status",
    createdAt,
  });
  const admin = testEnv.authenticatedContext("admin1", adminToken);
  await assertSucceeds(getDoc(doc(admin.firestore(), "adminLog", "log1")));
  await assertFails(
    setDoc(doc(admin.firestore(), "adminLog", "log2"), {
      actorId: "admin1",
      action: "delete",
      createdAt,
    }),
  );
  await assertSucceeds(setDoc(doc(admin.firestore(), "groups", "g1"), groupDoc()));
});

function reportDoc(overrides = {}) {
  return {
    reporterId: "athlete1",
    targetType: "post",
    targetId: "post-1",
    targetAuthorId: "coach1",
    targetPath: "posts/post-1",
    reason: "offensive",
    details: "Sértő szöveg.",
    snapshot: "Holnap edzés.",
    status: "open",
    createdAt,
    ...overrides,
  };
}

test("a config/app mindenkié, írni csak az admin tudja", async () => {
  await seed({
    admin1: userDoc({
      id: "admin1",
      email: "info@sarosigyorgy.hu",
      role: "admin",
      status: "active",
    }),
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      role: "member",
      status: "active",
    }),
  });
  const guest = testEnv.unauthenticatedContext();
  await assertSucceeds(getDoc(doc(guest.firestore(), "config", "app")));
  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertFails(
    setDoc(doc(athlete.firestore(), "config", "app"), {
      minVersion: "0.5.0",
    }),
  );
  const admin = testEnv.authenticatedContext("admin1", adminToken);
  await assertSucceeds(
    setDoc(doc(admin.firestore(), "config", "app"), {
      minVersion: "0.5.0",
      latestVersion: "0.5.0",
    }),
  );
});

test("jelentést a beküldő hoz létre, olvasni csak az admin tudja", async () => {
  await seed({
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      role: "member",
      status: "active",
    }),
    athlete2: userDoc({
      id: "athlete2",
      email: "athlete2@example.com",
      role: "member",
      status: "active",
    }),
    admin1: userDoc({
      id: "admin1",
      email: "info@sarosigyorgy.hu",
      role: "admin",
      status: "active",
    }),
  });
  const athlete = testEnv.authenticatedContext("athlete1", {
    email: "athlete@example.com",
  });
  await assertSucceeds(
    setDoc(doc(athlete.firestore(), "reports", "r1"), reportDoc()),
  );
  await assertFails(getDoc(doc(athlete.firestore(), "reports", "r1")));
  const other = testEnv.authenticatedContext("athlete2", {
    email: "athlete2@example.com",
  });
  await assertFails(getDoc(doc(other.firestore(), "reports", "r1")));
  const admin = testEnv.authenticatedContext("admin1", adminToken);
  await assertSucceeds(getDoc(doc(admin.firestore(), "reports", "r1")));
});

test("letiltás után a chatüzenet elutasítva", async () => {
  await seed({
    athlete1: userDoc({
      id: "athlete1",
      email: "athlete@example.com",
      role: "member",
      status: "active",
    }),
    athlete2: userDoc({
      id: "athlete2",
      email: "athlete2@example.com",
      role: "member",
      status: "active",
    }),
  });
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "conversations", "c-block"), {
      memberIds: ["athlete1", "athlete2"],
      type: "direct",
      createdAt,
      updatedAt: createdAt,
      lastReadAt: {},
      hasMinor: false,
      guardianIds: [],
    });
    await setDoc(doc(context.firestore(), "users", "athlete1", "blocks", "athlete2"), {
      createdAt,
    });
  });
  const sender = testEnv.authenticatedContext("athlete2", {
    email: "athlete2@example.com",
  });
  await assertFails(
    setDoc(doc(sender.firestore(), "conversations", "c-block", "messages", "m2"), {
      senderId: "athlete2",
      text: "Szia",
      createdAt,
      deleted: false,
    }),
  );
});
