# Áruházi adatkezelés

Ez a jegyzet az App Store „App Privacy” és a Google Play „Data safety” űrlaphoz készült. A végleges jogi szöveg a ClubConfig `privacyPolicyUrl` és `termsOfUseUrl` címére kerül (most `TODO_SUBLI` helyettesítő).

## Milyen adatot gyűjt az app

- **Név és e-mail.** A regisztrációhoz és a belépéshez kell. A név a bejegyzéseken, hozzászólásokon és a taglistán látszik.
- **Jelszó.** Csak a Firebase Authentication tárolja, kivonatként. Az app nem látja vissza.
- **Születési dátum.** Kötelező, 18 év alatt nem lehet regisztrálni.
- **Profilkép és a posztokhoz feltöltött fotó, videó, dokumentum.** A tag maga tölti fel.
- **Bejegyzések, hozzászólások, reakciók és chatüzenetek.** A közösség többi tagja olvassa, a chatet csak a beszélgetés tagjai.
- **Lovas szint és edzéscsoport.** A profilon és a tagkezelésben.
- **Jelentések.** Aki jelent egy tartalmat, az indok és a szabad szöveg az adminhoz kerül.
- **Letiltás.** A letiltó és a letiltott azonosítója.
- **Készülék és appverzió.** A visszajelző e-mailbe kerül, ha a tag levelet ír. Az éles app a Firebase Crashlyticsnek hibanaplót küldhet (debugban nem). Az áruházi űrlapon ez termékhasználat és hibajelentés.

Az app nem kér helyadatot, névjegyzéket, és nem követ hirdetéshez.

## Mire használja

A fiók azonosítására, a közösségi hírfolyamra, a kétszemélyes üzenetküldésre, a tagok jóváhagyására és a sértő tartalom kezelésére. A kötelező frissítés csak a `config/app` verziószámát olvassa.

## Kivel osztja meg

Az adat a Google Firebase-ben van: Authentication, Cloud Firestore, Cloud Storage, Cloud Functions, és élesben Crashlytics. A klub adminja (info@sarosigyorgy.hu) látja a tagokat, a jelentéseket és a jóváhagyásra váró fiókokat. Más harmadik félnek az app nem adja tovább. Az adatvédelmi tájékoztató és a feltételek külső böngészőben nyílnak.

## Titkosítás

Az átvitel HTTPS-en megy a Firebase felé. A készüléken a belépési munkamenet a rendszer kulcstartójában van. Az app nem használ saját, a szállításon felüli titkosítást (`ITSAppUsesNonExemptEncryption` hamis).

## Törlés

A Profilon a „Fiókom törlése” a jelszó újra megadása után törli az Auth-fiókot, a profilt, a tagsági másolatot és a feltöltött képeket. A bejegyzések és a hozzászólások megmaradnak, a szerző neve „Törölt felhasználó” lesz, a képeik lekerülnek. Az admin fiókja így nem törölhető. Felfüggesztett fiók nem használja a közösséget, amíg az admin vissza nem engedi.
