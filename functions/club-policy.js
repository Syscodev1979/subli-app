/** A Subli csak felnőtt tagokat kezel. Ha false, a szülők bekerülnek a chatbe. */
const ADULTS_ONLY = true;

// A Subli nem enged csoportos beszélgetést. A Gastroyal igaz.
const ALLOW_GROUP_CHATS = false;

// Új és szerkesztett poszt csak a „Minden tag” célközönséggel mehet.
// A Firestore-szabály onlyAllAudience() függvénye ugyanezt mondja.
const ONLY_ALL_AUDIENCE = true;

module.exports = { ADULTS_ONLY, ALLOW_GROUP_CHATS, ONLY_ALL_AUDIENCE };
