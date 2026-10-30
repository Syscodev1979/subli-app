# Új klub: az admin e-mail cseréje

Az appban egyetlen admin lehet. A cím a tesztidőszakban is rögzített, és a szerver ellenőrzi: a szerep `admin`, és a bejelentkezett e-mail pontosan ez.

A Gastroyal Karate SE admin címe: `info@sarosigyorgy.hu`.

Más klubnál ezt a címet **mind a négy** helyen ki kell cserélni, ugyanarra a szövegre:

1. `lib/app/club_config.dart` — `ClubConfig.adminEmail`
2. `firestore.rules` — az `adminEmail()` függvény
3. `storage.rules` — az `isAdmin()` e-mail összehasonlítása
4. `functions/admin-identity.js` — az `ADMIN_EMAIL` konstans

Ezután a szabályokat és a függvényeket újra kell telepíteni.

Az admin szerepet az app nem tudja kiosztani, még az admin sem. Az első admin `users/{uid}` dokumentumát a Firebase konzolon kell létrehozni vagy átírni: `role: "admin"`, `status: "active"`, és az e-mail mező a fenti cím. A Firebase Auth fiók e-mailjének ugyanennek kell lennie.

A visszajelző cím (`ClubConfig.feedbackEmail`) ettől független.
