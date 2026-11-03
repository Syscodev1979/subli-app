const test = require("node:test");
const assert = require("node:assert/strict");
const {
  SIMPLE_MEMBERSHIP,
  registrationRoleAllowed,
  roleChangeAllowed,
} = require("../club-policy");

test("egyszerű tagságnál csak a member szerep regisztrálható", () => {
  assert.equal(SIMPLE_MEMBERSHIP, true);
  assert.equal(registrationRoleAllowed("member"), true);
  assert.equal(registrationRoleAllowed("coach"), false);
  assert.equal(registrationRoleAllowed("athlete"), false);
  assert.equal(registrationRoleAllowed("parent"), false);
  assert.equal(registrationRoleAllowed("admin"), false);
});

test("egyszerű tagságnál a szerep nem változik", () => {
  assert.equal(roleChangeAllowed("member", "member"), true);
  assert.equal(roleChangeAllowed("admin", "admin"), true);
  assert.equal(roleChangeAllowed("member", "coach"), false);
  assert.equal(roleChangeAllowed("athlete", "member"), false);
});
