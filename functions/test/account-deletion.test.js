const test = require("node:test");
const assert = require("node:assert/strict");
const {
  DELETED_USER_NAME,
  selfDeleteAllowed,
  reportActionAllowed,
} = require("../account-deletion");

test("a tag törölheti a fiókját, az admin nem", () => {
  assert.equal(DELETED_USER_NAME, "Törölt felhasználó");
  assert.equal(selfDeleteAllowed({ role: "member", email: "a@example.com" }).ok, true);
  assert.equal(selfDeleteAllowed({ role: "admin", email: "info@sarosigyorgy.hu" }).reason, "admin");
  assert.equal(
    selfDeleteAllowed({ role: "member", email: "INFO@sarosigyorgy.hu" }).reason,
    "admin",
  );
  assert.equal(selfDeleteAllowed(null).reason, "missing");
});

test("a jelentés lezárása, elrejtése, törlése és a felfüggesztés érvényes", () => {
  assert.equal(reportActionAllowed("hide"), true);
  assert.equal(reportActionAllowed("delete"), true);
  assert.equal(reportActionAllowed("suspend"), true);
  assert.equal(reportActionAllowed("close"), true);
  assert.equal(reportActionAllowed("ban"), false);
});
