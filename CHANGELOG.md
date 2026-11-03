# Subli

## 0.5.0

### Hozzáadva

- Induláskor az app a `config/app` dokumentum `minVersion` és `latestVersion` mezőjét veti össze a saját verziójával. A minimum alatt egy bezárhatatlan frissítési képernyő jelenik meg, a legújabb verzió alatt csak egy bezárható jelzés. Ha a dokumentum nem olvasható, az app nem blokkol.
- A Profilon a „Fiókom törlése” a jelszó újra megadása után törli a fiókot, a profilt és a feltöltött képeket. A bejegyzések és a hozzászólások megmaradnak, a szerző „Törölt felhasználó” lesz. Az admin fiókja így nem törölhető.
- Bejegyzés, hozzászólás, chatüzenet és idegen profil jelenthető. A jelentést csak az admin látja, elrejtheti vagy törölheti a tartalmat, felfüggesztheti a tagot, és lezárhatja a jelentést. Egy tag letilthat egy másikat: a letiltott tartalma nem látszik, és chatüzenetet sem válthatnak. A letiltás a profilon feloldható.
- A regisztráció és a profil alja az adatvédelmi tájékoztatóra és a felhasználási feltételekre mutat. A címek a ClubConfig-ban vannak, amíg nincs végleges oldal, `TODO_SUBLI` helyettesítő.
- Az iOS engedélykérések magyarul szólnak, és van PrivacyInfo.xcprivacy. Az áruházi űrlaphoz a `docs/ARUHAZI_ADATKEZELES.md` foglalja össze a gyűjtött adatokat.
- A verzió `0.5.0+6`.

## 0.4.0

### Változtatva

- A belépés után a logó mellett minden képernyőn a „Subli Lovas Közösségi App” cím látszik. Szűk kijelzőn két sorba törik, a rövid „Subli” név nem jelenik meg.
- A bejegyzés kategóriája Poszt, nem Hír. A sorrend: Poszt, Közlemény, Esemény, Lovaink. Az Edzés és az Eredmény kikerült. Új bejegyzés alapból Poszt.
- A regisztráció nem kér szerepet és lovas szintet. Minden új fiók tag, a jóváhagyás megmarad. A tagok oldalán a szerep nem szerkeszthető. Egy admin van, az info@sarosigyorgy.hu cím.
- A mancs helyett patkó van a hírfolyam végén, az üres hírfolyamon, a szerkesztőben és a Lovaink kategóriánál.
- A verzió `0.4.0+5`.

## 0.3.0

### Változtatva

- A fejlesztői app a helyettesítő Firebase-kulccsal magától a helyi emulátorra csatlakozik. A sima Subli DEV indító és a szimulátoron az ikon is a belépési oldalra visz. Ha a próbaszerver nem fut, a belépés megmondja: `./tool/run_dev.sh`. Az éles flavor továbbra is a „nincs összekötve” oldalon marad.
- A `./tool/run_dev.sh` elindítja az emulátort, üres adatbázisnál betölti a mintaadatot, majd a futó szimulátoron elindítja az appot.
- Csoportos beszélgetés nem hozható létre, adminnak sem. Csak a kétszemélyes chat marad. A szerver és a Firestore-szabály is elutasítja a kettőnél több tagot, és meglévő chathez nem lehet új tagot adni.
- Posztoláskor a célközönség a Subli klubban csak „Minden tag”. A választó nem jelenik meg. Más célközönséget a szabály sem fogad el.
- A verzió `0.3.0+4`.

## 0.2.3

### Változtatva

- Az alkalmazásikon a teljes Subli logó, a PAARDENVOEDERS felirattal. A fejlesztői ikonon a DEV sáv megmarad. Az iOS és az Android ikonok mindkét flavorra újragenerálva.
- A verzió `0.2.3+5`.

## 0.2.2

### Változtatva

- A belépési oldalon a logó alatt a „Subli Lovas Közösségi App” cím látszik, alatta a sublilotapok.hu támogatói link, a regisztráció alatt pedig a „Készítette: Sysco System” sor. Ha egy felirat a ClubConfig-ban null, az a sor kimarad.
- A verzió `0.2.2+4`.

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
