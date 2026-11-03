/** A Subli csak felnőtt tagokat kezel. Ha false, a szülők bekerülnek a chatbe. */
const ADULTS_ONLY = true;

// A Subli nem enged csoportos beszélgetést. A Gastroyal igaz.
const ALLOW_GROUP_CHATS = false;

// Új és szerkesztett poszt csak a „Minden tag” célközönséggel mehet.
// A Firestore-szabály onlyAllAudience() függvénye ugyanezt mondja.
const ONLY_ALL_AUDIENCE = true;

// Egyszerű tagság: új fiók csak member, a szerep utána nem változik.
// A Gastroyal hamis. A Firestore simpleMembership() ugyanezt mondja.
const SIMPLE_MEMBERSHIP = true;

// Subli: minden jóváhagyott tag posztolhat, az edző nem kap külön jogot.
// A Gastroyal hamis: ott az edző írja a bejegyzést és látja a vezetőségi kört.
// A Firestore és a Storage membersMayPost() ugyanezt mondja.
const MEMBERS_MAY_POST = true;

function registrationRoleAllowed(role) {
  if (SIMPLE_MEMBERSHIP) return role === "member";
  return role === "athlete" || role === "parent" || role === "coach";
}

function roleChangeAllowed(before, after) {
  if (!SIMPLE_MEMBERSHIP) return true;
  return before === after;
}

module.exports = {
  ADULTS_ONLY,
  ALLOW_GROUP_CHATS,
  ONLY_ALL_AUDIENCE,
  SIMPLE_MEMBERSHIP,
  MEMBERS_MAY_POST,
  registrationRoleAllowed,
  roleChangeAllowed,
};
