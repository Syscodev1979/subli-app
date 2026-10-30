const test = require("node:test");
const assert = require("node:assert/strict");
const {
  ADMIN_EMAIL,
  DELETED_NAME,
  tokenIsVerifiedAdmin,
  userRecordIsAdmin,
  memberAuditPlan,
  deletionGuard,
  unlinkPlan,
  withoutMember,
} = require("../admin-identity");

test("admin csak a megerősített kijelölt címmel igaz", () => {
  assert.equal(tokenIsVerifiedAdmin({ email: ADMIN_EMAIL, email_verified: true }), true);
  assert.equal(tokenIsVerifiedAdmin({ email: ADMIN_EMAIL, email_verified: false }), false);
  assert.equal(tokenIsVerifiedAdmin({ email: "mas@example.com", email_verified: true }), false);
  assert.equal(
    userRecordIsAdmin({ role: "admin", status: "active", email: ADMIN_EMAIL }),
    true,
  );
  assert.equal(
    userRecordIsAdmin({ role: "admin", status: "active", email: "mas@example.com" }),
    false,
  );
  assert.equal(
    userRecordIsAdmin({ role: "coach", status: "active", email: ADMIN_EMAIL }),
    false,
  );
});

test("szerep és csoport változása naplózandó, a törlés nem itt", () => {
  const plan = memberAuditPlan(
    { role: "athlete", status: "active", groupIds: ["a"] },
    { role: "coach", status: "active", groupIds: ["a", "b"], auditBy: "admin1" },
  );
  assert.equal(plan.action, "role+groups");
  assert.equal(plan.actorId, "admin1");
  assert.equal(memberAuditPlan({ role: "athlete" }, null), null);
  assert.equal(
    memberAuditPlan(
      { role: "athlete", status: "active", groupIds: ["a"] },
      { role: "athlete", status: "active", groupIds: ["a"] },
    ),
    null,
  );
});

test("deleteMember saját fiókot és admint nem töröl, a kapcsolatokat igen", () => {
  assert.equal(deletionGuard({ callerId: "a", targetId: "a", target: { role: "athlete" } }).reason, "self");
  assert.equal(
    deletionGuard({
      callerId: "admin",
      targetId: "other",
      target: { role: "admin", email: ADMIN_EMAIL },
    }).reason,
    "admin",
  );
  assert.equal(
    deletionGuard({
      callerId: "admin",
      targetId: "athlete",
      target: { role: "athlete", email: "a@example.com" },
    }).ok,
    true,
  );
  assert.deepEqual(unlinkPlan({ childIds: ["c1"], parentIds: ["p1", ""] }), {
    childIds: ["c1"],
    parentIds: ["p1"],
  });
  assert.deepEqual(withoutMember(["a", "b", "a"], "a"), ["b"]);
  assert.equal(DELETED_NAME, "Törölt tag");
});
