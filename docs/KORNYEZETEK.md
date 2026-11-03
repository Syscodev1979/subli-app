# Környezetek

A fejlesztői és az éles app külön települ, külön Firebase-projekthez beszél, és a fejlesztői ikonon DEV felirat van. Éles adatot a dev változatból nem lehet írni.

| | Fejlesztői | Éles |
| --- | --- | --- |
| Flavor | `dev` | `prod` |
| Megjelenő név | Gastroyal DEV | Gastroyal |
| Azonosító | `hu.gastroyalkarate.app.dev` | `hu.gastroyalkarate.app` |
| Firebase-projekt | `subli-app-dev` | `subli-app` |
| Régió | `europe-west3` | `europe-west3` |
| Beállítások | `lib/firebase_options_dev.dart` | `lib/firebase_options_prod.dart` |
| Android | `android/app/src/dev/google-services.json` | `android/app/src/prod/google-services.json` |
| iOS | `ios/config/dev/GoogleService-Info.plist` | `ios/config/prod/GoogleService-Info.plist` |

Egyik projekt sincs összekötve, amíg a flavor `firebase_options` fájljának kulcsa `REPLACE_`-szal kezdődik. Ilyenkor az app egy tájékoztató képernyőt mutat („A Firebase-projekt még nincs összekötve”), és nem hívja a `Firebase.initializeApp`-ot. Az iOS build kiveszi a `GoogleService-Info.plist`-et a csomagból, ha a forrás hiányzik vagy a helyettesítő kulcsot tartalmazza, mert arra az iOS Firebase induláskor leállna. A natív json és plist fájlok a `flutterfire configure` után jönnek létre.

Az azonosítók a `ClubConfig`-ban is szerepelnek (`prodApplicationId`, `devApplicationId`).

## Indítás

A flavor kötelező. Enélkül a debug build a dev környezetet választja, a release build az élest.

```bash
flutter run --flavor dev
flutter run --flavor prod
```

A Cursor / VS Code indítók: **Gastroyal DEV** és **Gastroyal ÉLES** (`.vscode/launch.json`).

iOS-en a `dev` és a `prod` scheme a `Debug-dev` / `Release-prod` konfigurációkat használja. Az Archive mindig a `prod` scheme-mel készül.

## Firebase-projektek összekötése

A `subli-app` és a `subli-app-dev` projektet kézzel kell létrehozni, `europe-west3` régióval. Kell hozzájuk e-mail/jelszó belépés, Firestore, Storage, Functions (Blaze csomag) és Crashlytics. A függvények kódja eleve `europe-west3`-ra van állítva. Ezek a projektek még nem léteznek; a létrehozásuk nem ennek a tárolónak a dolga.

Ha a projekt megvan és a `flutterfire` be van jelentkezve, ezt a két parancsot kell futtatni a tároló gyökeréből. Új Android- és iOS-appot regisztrálnak a megadott azonosítóval. A régi `com.example` appok nem jók helyettük.

Éles:

```bash
flutterfire configure \
  --project=subli-app \
  --out=lib/firebase_options_prod.dart \
  --platforms=android,ios \
  --ios-bundle-id=hu.gastroyalkarate.app \
  --android-package-name=hu.gastroyalkarate.app \
  --ios-out=ios/config/prod/GoogleService-Info.plist \
  --android-out=android/app/src/prod/google-services.json \
  --yes \
  --overwrite-firebase-options
```

Fejlesztői:

```bash
flutterfire configure \
  --project=subli-app-dev \
  --out=lib/firebase_options_dev.dart \
  --platforms=android,ios \
  --ios-bundle-id=hu.gastroyalkarate.app.dev \
  --android-package-name=hu.gastroyalkarate.app.dev \
  --ios-out=ios/config/dev/GoogleService-Info.plist \
  --android-out=android/app/src/dev/google-services.json \
  --yes \
  --overwrite-firebase-options
```

A generált Dart-osztály neve maradjon `DefaultFirebaseOptions`. A `lib/main.dart` a flavor szerint választ a két fájl közül.

A parancs átírhatja a `firebase.json` elejét, és a gyökérbe tehet egy `android/app/google-services.json`-t. A gyökér fájlt törölni kell, mert a flavor saját json-ja a mérvadó. A `firebase.json`-ban maradjon meg a Firestore, a Storage, a Functions és az emulátor, valamint mindkét flavor kimeneti útja. A `.firebaserc` aliasai: `prod` = `subli-app`, `dev` = `subli-app-dev`.

## Telepítés az egyik vagy a másik projektre

Először mindig a dev. Ha ott a szabály, az index, a függvény és a Storage-szabály rendben van, utána mehet az éles.

Fejlesztői:

```bash
firebase deploy -P dev --only firestore:rules,firestore:indexes,storage,functions
```

Éles:

```bash
firebase deploy -P prod --only firestore:rules,firestore:indexes,storage,functions
```

Egy rész is telepíthető, például csak a szabály:

```bash
firebase deploy -P dev --only firestore:rules
firebase deploy -P prod --only firestore:rules,firestore:indexes,storage
```

Az indexek a telepítés után még percekig épülhetnek. A `firebase-functions` csomagot nem kell frissíteni: a telepítő figyelmeztethet, hogy elavult, a jelenlegi major verzió törné a függvényeket.

A Crashlytics mindkét környezetben be van kötve. Debug módban nem küld jelentést. A jelentéshez csak a felhasználó `uid`-ja kerül, név és e-mail nem. iOS release buildnél a dSYM feltöltő lefut, ha a plist már valódi kulcsot tartalmaz.
