# Új klub: az admin e-mail cseréje

Az appban egyetlen admin lehet. A cím kisbetűsen van tárolva, és a szerver a bejövő címet kisbetűsítve hasonlítja össze: a szerep `admin`, és a bejelentkezett e-mail ez.

A Subli – lovas közösségi app admin címe: `info@sarosigyorgy.hu`.

Más klubnál ezt a címet **mind a négy** helyen ki kell cserélni, ugyanarra a szövegre:

1. `lib/app/club_config.dart` — `ClubConfig.adminEmail`
2. `firestore.rules` — az `adminEmail()` függvény
3. `storage.rules` — az `isAdmin()` e-mail összehasonlítása
4. `functions/admin-identity.js` — az `ADMIN_EMAIL` konstans

Ezután a szabályokat és a függvényeket újra kell telepíteni.

Az admin szerepet az app nem tudja kiosztani, még az admin sem. Az első admin `users/{uid}` dokumentumát a Firebase konzolon kell létrehozni vagy átírni: `role: "admin"`, `status: "active"`, és az e-mail mező a fenti cím. A Firebase Auth fiók e-mailjének ugyanennek kell lennie.

A visszajelző cím (`ClubConfig.feedbackEmail`) ettől független.

## Közös javítások átvétele a Gastroyal és a Subli között

A közös működés javítását át lehet vinni a két app között. A klub saját arculatát és szabályait nem. Ezeket a fájlokat és részeket soha ne másold át:

- `lib/app/club_config.dart`
- `lib/app/constants.dart`
- `firestore.rules` klubfüggő részei: admin cím, 18 év, kategóriák, reakciók, lovas szintek
- `storage.rules` klubfüggő részei: admin cím
- `functions/admin-identity.js`
- `functions/club-policy.js`
- `.firebaserc`
- `lib/firebase_options_dev.dart` és `lib/firebase_options_prod.dart`
- `assets/branding`
- az alkalmazásikonok
- a kezdőképernyő (`flutter_native_splash` és a generált splash képek)
