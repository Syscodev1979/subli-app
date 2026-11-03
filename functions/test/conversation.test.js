const test = require("node:test");
const assert = require("node:assert/strict");
const {
  isMinor,
  planConversation,
  assertDirectChat,
  findExisting,
  addParents,
  memberKey,
  nameKeywords,
} = require("../conversation-logic");
const { ALLOW_GROUP_CHATS, ONLY_ALL_AUDIENCE } = require("../club-policy");

const today = new Date(2026, 9, 22);

function user(id, role, birthDate, parentIds = []) {
  return { id, role, birthDate, parentIds };
}

const minorBirth = new Date(2012, 2, 4);
const otherMinorBirth = new Date(2014, 5, 1);
const adultBirth = new Date(1990, 3, 2);

test("a 18. születésnap előtt kiskorú, a napján már nem", () => {
  assert.equal(isMinor(user("a", "athlete", new Date(2008, 9, 23)), today), true);
  assert.equal(isMinor(user("a", "athlete", new Date(2008, 9, 22)), today), false);
  assert.equal(isMinor(user("c", "coach", minorBirth), today), false);
  assert.equal(isMinor(user("a", "athlete", null), today), false);
});

test("18 év feletti klubban a szülők nem kerülnek a beszélgetésbe", () => {
  const plan = planConversation(
    user("coach", "coach", adultBirth),
    user("child", "athlete", minorBirth, ["parent-1", "parent-2"]),
    today,
    true,
  );
  assert.deepEqual(plan.memberIds, ["child", "coach"]);
  assert.deepEqual(plan.guardianIds, []);
  assert.equal(plan.hasMinor, false);
  assert.equal(plan.type, "direct");
});

test("felnőtt és kiskorú beszélgetésébe bekerülnek a szülők", () => {
  const plan = planConversation(
    user("coach", "coach", adultBirth),
    user("child", "athlete", minorBirth, ["parent-1", "parent-2"]),
    today,
  );
  assert.deepEqual(plan.memberIds, ["child", "coach", "parent-1", "parent-2"]);
  assert.deepEqual(plan.guardianIds, ["parent-1", "parent-2"]);
  assert.equal(plan.hasMinor, true);
  assert.equal(plan.type, "group");
});

test("két kiskorú beszélgetésébe mindkettő szülei bekerülnek", () => {
  const plan = planConversation(
    user("child-a", "athlete", minorBirth, ["parent-a"]),
    user("child-b", "athlete", otherMinorBirth, ["parent-b", "parent-c"]),
    today,
  );
  assert.deepEqual(plan.memberIds, [
    "child-a",
    "child-b",
    "parent-a",
    "parent-b",
    "parent-c",
  ]);
  assert.deepEqual(plan.guardianIds, ["parent-a", "parent-b", "parent-c"]);
  assert.equal(plan.type, "group");
});

test("kiskorú és a saját szülője közé nem kerül más", () => {
  const plan = planConversation(
    user("child", "athlete", minorBirth, ["parent-1", "parent-2"]),
    user("parent-1", "parent", adultBirth),
    today,
  );
  assert.deepEqual(plan.memberIds, ["child", "parent-1"]);
  assert.deepEqual(plan.guardianIds, []);
  assert.equal(plan.type, "direct");

  const reverse = planConversation(
    user("parent-1", "parent", adultBirth),
    user("child", "athlete", minorBirth, ["parent-1", "parent-2"]),
    today,
  );
  assert.deepEqual(reverse.memberIds, ["child", "parent-1"]);
});

test("azonos tagösszetételnél a meglévő beszélgetés jön vissza", () => {
  const existing = {
    id: "conv-1",
    memberIds: ["child", "coach", "parent-1"],
  };
  const found = findExisting(
    [existing],
    ["parent-1", "coach", "child"],
  );
  assert.equal(found.id, "conv-1");
  assert.equal(memberKey(["b", "a"]), memberKey(["a", "b"]));
  assert.equal(
    findExisting([existing], ["coach", "child"]),
    null,
  );
});

test("új szülő bekerül a kiskorú meglévő beszélgetéseibe", () => {
  const direct = addParents(
    {
      memberIds: ["child", "parent-1"],
      guardianIds: [],
      hasMinor: true,
      type: "direct",
    },
    ["parent-2"],
  );
  assert.deepEqual(direct.memberIds, ["child", "parent-1", "parent-2"]);
  assert.deepEqual(direct.guardianIds, ["parent-2"]);
  assert.equal(direct.type, "group");

  const withCoach = addParents(
    {
      memberIds: ["child", "coach", "parent-1"],
      guardianIds: ["parent-1"],
      hasMinor: true,
      type: "group",
    },
    ["parent-2"],
  );
  assert.ok(withCoach.memberIds.includes("parent-2"));
  assert.deepEqual(withCoach.guardianIds, ["parent-1", "parent-2"]);

  const unchanged = addParents(withCoach, ["parent-2"]);
  assert.equal(unchanged, withCoach);
});

test("csoportos chat tilos, a kétszemélyes megengedett", () => {
  assert.equal(ALLOW_GROUP_CHATS, false);
  assert.equal(ONLY_ALL_AUDIENCE, true);
  assert.throws(
    () => assertDirectChat(["a", "b", "c"], ALLOW_GROUP_CHATS),
    (error) => error.code === "group-chat-forbidden",
  );
  assert.doesNotThrow(() => assertDirectChat(["a", "b"], ALLOW_GROUP_CHATS));
  assert.doesNotThrow(() => assertDirectChat(["a", "b", "c"], true));

  const direct = planConversation(
    user("admin", "admin", adultBirth),
    user("member", "athlete", adultBirth),
    today,
    true,
  );
  assert.doesNotThrow(() => assertDirectChat(direct.memberIds, ALLOW_GROUP_CHATS));
  assert.equal(direct.memberIds.length, 2);
  assert.equal(direct.type, "direct");
});

test("a tagkereső előtagjai ékezet nélkül készülnek", () => {
  assert.deepEqual(nameKeywords("Kovács Anna"), [
    "ko",
    "kov",
    "kova",
    "kovac",
    "kovacs",
    "an",
    "ann",
    "anna",
  ]);
});
