# Subli

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
