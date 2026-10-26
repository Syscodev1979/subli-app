# Kiadás a TestFlightra

Az első tesztelői kiadás az `1.0.0+19`. A `+` utáni szám a build száma: minden új feltöltésnél nagyobbnak kell lennie, akkor is, ha a verziószám marad.

Az iOS minimum verzió 15.0. Az alkalmazás csak a rendszer szokásos titkosítását használja, ezért az `Info.plist` `ITSAppUsesNonExemptEncryption` értéke `NO`. A fotó, a kamera és a mikrofon engedélyszövege magyar.

A TestFlight-csomag mindig a **prod** flavor. A dev változat a `gastroyal-karate-dev` projekthez való, és nem kerül a tesztelőkhöz.

## 1. Verziószám

A `pubspec.yaml` `version` sora adja a verziót és a build számot:

```yaml
version: 1.0.0+19
```

Következő tesztcsomagnál például `1.0.0+20`. Ha a viselkedés is változik, a verzió is nő (`1.0.1+20`), és a `CHANGELOG.md` elejére bekerül, mi változott.

## 2. Csomag készítése

Aláíráshoz Apple Developer fiók, a `hu.gastroyalkarate.app` App ID, és az Xcode-ban kiválasztott csapat kell. A részletek a `docs/KORNYEZETEK.md`-ben vannak, ha a Firebase-t is újra kell kötni.

### Xcode Archive

1. `open ios/Runner.xcworkspace`
2. Fent a scheme: **prod** (ne a Runner és ne a dev).
3. Cél: **Any iOS Device (arm64)**.
4. Product → Archive.
5. Az Organizerben Distribute App → App Store Connect → Upload.

### Parancssor és Transporter

```bash
flutter build ipa --flavor prod --release
```

A kész fájl: `build/ios/ipa/*.ipa`. A Transporter alkalmazásba behúzva feltölthető az App Store Connectra.

Ha a csomag aláírás nélkül csak ellenőrizendő (még nincs csapat kiválasztva):

```bash
flutter build ios --flavor prod --release --no-codesign
```

Ez nem tölthető fel. A feltöltéshez a fenti `flutter build ipa` vagy az Archive kell, érvényes aláírással.

A release build a Crashlytics dSYM-et is feltölti, ha a prod `GoogleService-Info.plist` már a valódi éles kulcsokat tartalmazza.

## 3. Tesztelők meghívása

App Store Connect → az app → TestFlight.

- Belső tesztelő: App Store Connect-felhasználó, a build feldolgozása után azonnal telepíthet. Kis admincsapathoz ez a gyorsabb, ha mindenkinek van hozzáférése.
- Külső tesztelő: e-mail-cím elég. Csoportot kell létrehozni, abba kerül a 7–8 admin, és az első buildnél az Apple rövid béta-ellenőrzést kérhet. A további buildek ugyanabba a csoportba már külön ellenőrzés nélkül kimehetnek, amíg a megfelelőségi válasz nem változik.

A tesztelő a TestFlight appból telepít. A telefonon a név **Gastroyal**, az azonosító `hu.gastroyalkarate.app`. A Gastroyal DEV nem ez a csomag.

## 4. Új tesztverzió

1. A változás bekerül a `CHANGELOG.md`-be, a `pubspec.yaml` build száma nő.
2. `flutter test` és `dart analyze lib test` zöld.
3. Új Archive vagy `flutter build ipa --flavor prod --release`, majd feltöltés.
4. Meg kell várni, amíg az App Store Connect feldolgozza a buildet (a dSYM és a megfelelőség is ilyenkor készül el).
5. A buildet a meglévő tesztelői csoporthoz kell adni. A TestFlight értesíti a korábbi telepítőket.
6. Ha szabály, index, függvény vagy Storage-szabály is változott: először `firebase deploy -P dev --only …`, és csak utána `firebase deploy -P prod --only …`. A pontos parancsok a `docs/KORNYEZETEK.md`-ben vannak.

A profil alján a telepített verzió látszik, halványan. A „Visszajelzés küldése” e-mailt nyit a `ClubConfig.feedbackEmail` címre, a verzióval és a készülék típusával.
