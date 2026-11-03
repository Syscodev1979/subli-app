/** Tiszta szabályok a beszélgetés tagjairól. A Cloud Functions ezt hívja. */

function sorted(ids) {
  return [...ids].sort();
}

function memberKey(ids) {
  return sorted(ids).join("|");
}

function isMinor(user, today) {
  if (!user || user.role !== "athlete" || !user.birthDate) return false;
  const birth = user.birthDate instanceof Date ? user.birthDate : new Date(user.birthDate);
  if (Number.isNaN(birth.getTime())) return false;
  const day = new Date(today.getFullYear(), today.getMonth(), today.getDate());
  const eighteenth = new Date(birth.getFullYear() + 18, birth.getMonth(), birth.getDate());
  return day < eighteenth;
}

/**
 * A hívó és a címzett mellé bekerülnek a kiskorúak aktív szülei.
 * Kivétel: a beszélgetés csak a kiskorú és a saját szülője között van.
 *
 * A parentIds listában már csak aktív szülők szerepeljenek.
 */
function planConversation(caller, other, today = new Date(), adultsOnly = false) {
  if (adultsOnly) {
    return {
      memberIds: sorted([caller.id, other.id]),
      guardianIds: [],
      hasMinor: false,
      type: "direct",
    };
  }
  const minors = [caller, other].filter((person) => isMinor(person, today));
  if (minors.length === 1) {
    const minor = minors[0];
    const counterpart = minor.id === caller.id ? other : caller;
    if ((minor.parentIds || []).includes(counterpart.id)) {
      return {
        memberIds: sorted([caller.id, other.id]),
        guardianIds: [],
        hasMinor: true,
        type: "direct",
      };
    }
  }

  const ids = new Set([caller.id, other.id]);
  const guardians = [];
  for (const minor of minors) {
    for (const parentId of minor.parentIds || []) {
      if (!ids.has(parentId)) {
        ids.add(parentId);
        guardians.push(parentId);
      }
    }
  }
  const memberIds = sorted([...ids]);
  return {
    memberIds,
    guardianIds: sorted(guardians),
    hasMinor: minors.length > 0,
    type: memberIds.length > 2 ? "group" : "direct",
  };
}

/** 2-nél több tag tilos, ha a klub nem enged csoportos chatet. */
function assertDirectChat(memberIds, allowGroupChats) {
  if (!allowGroupChats && memberIds.length > 2) {
    const error = new Error("Csoportos beszélgetés nem hozható létre.");
    error.code = "group-chat-forbidden";
    throw error;
  }
}

function findExisting(conversations, memberIds) {
  const key = memberKey(memberIds);
  return conversations.find((item) => memberKey(item.memberIds) === key) || null;
}

/** Új szülő bekerül a kiskorú minden meglévő beszélgetésébe. */
function addParents(conversation, parentIds) {
  const missing = parentIds.filter((id) => !conversation.memberIds.includes(id));
  if (missing.length === 0) return conversation;
  const memberIds = sorted([...conversation.memberIds, ...missing]);
  return {
    ...conversation,
    memberIds,
    guardianIds: sorted([...(conversation.guardianIds || []), ...missing]),
    hasMinor: true,
    type: memberIds.length > 2 ? "group" : "direct",
  };
}

const accents = {
  á: "a",
  é: "e",
  í: "i",
  ó: "o",
  ö: "o",
  ő: "o",
  ú: "u",
  ü: "u",
  ű: "u",
};

function foldName(value) {
  return value.toLowerCase().replace(/[áéíóöőúüű]/g, (char) => accents[char] || char);
}

/** Előtagok a tagkeresőhöz, legalább 2 karakter. */
function nameKeywords(name) {
  const words = foldName(name).split(/[^\p{L}\p{N}]+/u).filter((word) => word.length >= 2);
  const keys = new Set();
  for (const word of words) {
    for (let size = 2; size <= word.length && size <= 24; size += 1) {
      keys.add(word.slice(0, size));
    }
  }
  return [...keys].slice(0, 50);
}

module.exports = {
  sorted,
  memberKey,
  isMinor,
  planConversation,
  assertDirectChat,
  findExisting,
  addParents,
  nameKeywords,
};
