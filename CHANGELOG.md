# Subli

## 0.2.1

### Hozzáadva

- Helyi emulátor mód a `--dart-define=USE_EMULATOR=true` zászlóval. A Firebase a `demo-subli` projekttel a gépen futó emulátorhoz csatlakozik, és a sarokban EMULÁTOR szalag látszik. A zászló nélkül minden a régi.
- Indító: Subli DEV (emulátor). A `tool/emulator_start.sh` elindítja az emulátort, a `tool/seed_emulator.mjs` mintaadatot tölt bele. Az adatok a `.emulator-data` mappában maradnak, ez nincs a gitben.
- A verzió `0.2.1+3`.

## 0.2.0

### Változtatva

- A márkaszínek a Subli logóhoz igazodnak. A gombok, linkek és aktív ikonok `#D7262B`, a nagy felületek `#EF3D42`. A hibaüzenet borostyán `#B45309`, és mindig ikon is van mellette.
- Mindenhol a teljes Subli logó látszik. Az alkalmazásikon piros, a fejlesztői változaton DEV szalag van. A kezdőképernyő fehér, sötét módban is.
- A verzió `0.2.0+2`.

## 0.1.1

### Változtatva

- Az egyetlen admin cím `info@sarosigyorgy.hu`. Kisbetűsen van tárolva, és a kliens, a Firestore-szabály, a Storage-szabály és a Cloud Functions is kisbetűsítve hasonlítja össze. Más cím, köztük a korábbi helyettesítő, nem kap admin jogot.
- A visszajelző cím továbbra is helyettesítő.
- A verzió `0.1.1+2`.

## 0.1.0

Első kiadás, leválasztva a Gastroyal Karate SE alkalmazásról. A Firebase-projektek még nincsenek összekötve, és nem történt deploy. A korábbi napló változatlanul a `docs/GASTROYAL_CHANGELOG.md` fájlban van.

### Hozzáadva

- Csak 18. életévüket betöltött tagok regisztrálhatnak. Nincs „Szülő vagyok” lehetőség, a születési dátum kötelező, és 18 év alatt az űrlap nem enged tovább. A Firestore-szabály a létrehozáskor elutasítja a `parent` szerepet és a 18 év alatti születési dátumot. A szülő–gyermek funkciók rejtve vannak; `adultsOnly = false` mellett a közös kód a régi viselkedést adja vissza a felületen.
- Lovas alapértékek: szintek (Kezdő, Haladó, Versenyző), kategóriák (Hír, Közlemény, Esemény, Edzés, Eredmény, Lovaink), csoportminták (Kezdők, Haladók, Díjugratók, Túralovasok), a `horse` reakció „Lovas!” felirattal, és a lovas chat-sablonok.

### Változtatva

- A név Subli, a csomag `subli_app`, az azonosító `hu.subli.app`, a fejlesztői `hu.subli.app.dev`. A megjelenő név „Subli”, illetve „Subli DEV”.
- A Gastroyal Firebase-projektazonosítók és a hozzájuk tartozó konfiguráció kikerült. Amíg a kulcs `REPLACE_`-szal kezdődik, az app tájékoztató képernyőt mutat, és nem indít hálózati hívást.
- A logó és az alkalmazásikon helyettesítő: piros kör, fehér S betűvel.
- A verzió `0.1.0+1`.
