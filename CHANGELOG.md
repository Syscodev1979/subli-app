# Változásnapló

## 1.0.0

### Hozzáadva

- Egyetlen admin: csak az `info@sarosigyorgy.hu` fiók kap admin jogot. A szerep az appból nem adható ki és nem vehető el.
- Tagok oldal a menüben: keresés, szűrés, összesítő, és a tag adatlapja. Szerep, státusz, öv, csoport és szülő–gyermek kapcsolat szerkeszthető.
- Felfüggesztés és végleges törlés. A törölt tag bejegyzései megmaradnak, a neve „Törölt tag” lesz. A felfüggesztett fiók csak egy tájékoztató képernyőt lát.
- Edzéscsoportok. Az admin kezeli őket, a profilokon címkeként látszanak.
- Adminnapló a szerep-, státusz-, csoport- és törlésműveletekről. A kliens nem írhatja.

### Változtatva

- Az edző továbbra is jóváhagyhat sportolót és szülőt, és állíthat övet. Tagot nem töröl, szerepet és csoportot nem módosít, a Tagok oldalt nem látja.
- Az admin joghoz a szerep és a kijelölt e-mail elég. A megerősítés nem kell, a hírfolyam és az adminfelületek megerősítő sávja kikerült.
- A bejelentkezés, a regisztráció és az elfelejtett jelszó egyszerű fehér oldalon van, sötét módban egyszínű sötét háttéren. Az e-mail mezőből az Enter a jelszóra lép, a jelszó mezőből beléptet, és a jelszókezelő felajánlhatja a mentett adatokat.

### Tesztelői kiadás

Az első tesztelői kiadás.

### Hozzáadva

- Külön fejlesztői és éles app. A fejlesztői neve Gastroyal DEV, az azonosítója `hu.gastroyalkarate.app.dev`, és az ikonján DEV felirat van. Az éles neve Gastroyal, azonosítója `hu.gastroyalkarate.app`.
- Indítóképernyő a klublogóval: világos módban fehér, sötét módban a szokásos sötét háttér.
- Hibajelentés a Firebase Crashlyticsbe, csak a felhasználó azonosítójával. Név és e-mail nem kerül bele, debug módban pedig nem küld jelentést.
- A profil alján halványan a verziószám, és a „Visszajelzés küldése”, ami e-mailt nyit a verzióval és a készülék típusával.

### Változtatva

- Az alkalmazásazonosító a `com.example` helyett a klub saját azonosítója.
- Az App Store exportmegfelelősége rögzítve: az app csak a rendszer szokásos titkosítását használja.

## 0.9.0

### Hozzáadva

- Bejegyzésnél megadható, ki láthatja: minden tag, edzők és adminok, szülők vagy sportolók. A minden tag kizárólagos, a többiből több is választható. A vezetőség mindig látja.
- A szűkebb bejegyzés a szerkesztőben bordó kerettel és lakattal, a hírfolyamon a célközönség feliratával jelenik meg. Szerkesztéskor a célközönség módosítható.
- Sportoló a mindenkihez és a sportolókhoz szóló híreket látja, szülő a mindenkihez és a szülőkhöz szólókat. Edző és admin mindent lát, a hozzászólással, a reakcióval és a csatolt fájllal együtt.

### Változtatva

- A célközönség nélküli régi bejegyzés minden tagnak számít. Az Adminisztráció / Karbantartás „Adatok frissítése” kitölti a mezőt.

## 0.8.1

### Hozzáadva

- Esemény bejegyzésnél megadható a dátum, a kezdés és az opcionális vége. Dátum nélkül nem tehető közzé, a vége nem előzheti meg a kezdést.
- A hírfolyamon naptárcsík mutatja a napot és az időtartamot. A nap a keresőbe is bekerül.

## 0.8.0

### Hozzáadva

- Saját profil a menüből: nagy profilkép arany gyűrűvel, név, szerepkör, sportolónál színes övfokozat, e-mail, születési dátum és edzéscsoport. A kép négyzetesen vágható, 512×512-es JPEG-ként töltődik fel.
- Övfokozatok a klubbeállításban, 10. kyu-tól 10. danig. Edző és admin állíthatja az adminisztráción vagy a sportoló profilján. A sportoló a saját övét nem módosíthatja.
- Szülőnél „Gyermekeim” szakasz. A szülő megnyithatja a gyerek profilját, és a profilképét cserélheti.
- Más tag profilja a hírfolyamból, a hozzászólásokból és a csevegésből. E-mail és születési dátum nem látszik. Az „Üzenet küldése” a meglévő beszélgetést nyitja.
- Regisztráción „Edző vagyok”. A fiók jóváhagyásig sportoló, arany „Edzőként jelentkezett” címkével. Csak admin hagyhatja jóvá edzőként vagy sportolóként.
- Dokumentum a bejegyzésben: PDF, Word, Excel és PowerPoint, fájlonként legfeljebb 20 MB, bejegyzésenként legfeljebb 5. A PDF az alkalmazásban lapozható és nagyítható, a többi a telefon alkalmazásával nyílik. A fájlnév a keresőbe is bekerül.

### Változtatva

- A hírfolyam „Kamera” gombja „Dokumentum”. A fotó és a videó galériából vagy kamerából választható.
- A név vagy a profilkép változása frissíti a taglistát, valamint a szerző bejegyzéseit és hozzászólásait.

## 0.7.2

### Változtatva

- A fejléc a klublogót és a teljes nevet mutatja („Gastroyal Karate SE”). 360 px alatt a rövid név marad. Sötét módban a logó finom világos hátteret kap, hogy látható maradjon.
- A keresés a hírfolyam tetejére került: teljes szélességű, lekerekített sáv, a listával együtt gördül. A fejlécben a logó, a téma-kapcsoló és a menü maradt. A találatok továbbra is ékezetfüggetlenek, kiemeltek, és a kategóriaszűrővel együtt működnek.

## 0.7.0

### Hozzáadva

- Üzenetek a hírfolyam jobb alsó gombjáról és a menüből. A gomb jelzi az olvasatlan beszélgetéseket.
- Beszélgetéslista, tagkereső és csevegés valós időben. A saját üzenet azonnal megjelenik, törölhető, és látszik, ha elolvasták.
- Sportoló és szülő gyors sablonjai, ha edző is a beszélgetésben van.
- Kiskorú sportoló beszélgetésébe a jóváhagyott szülők automatikusan bekerülnek, és ezt egy arany sáv jelzi. A szabályt a szerver kényszeríti ki.
- Az adminisztráció Karbantartás részén a taglista feltölthető a meglévő aktív tagokból.

## 0.6.0

### Hozzáadva

- A lista alján jelzés, ha minden bejegyzés betöltődött. Két képernyőnyi görgetés után jobb alul egy gomb a tetejére ugrik. Új bejegyzésnél felül egy „Új bejegyzések” jelzés frissít.
- Kategóriák: Hír, Közlemény, Eredmény, Edzés, Esemény. A szerkesztőben választható, a kártyán címke, a hírfolyamon szűrő. A választott szűrő a munkamenetben megmarad.
- Keresés a fejlécből. Ékezetfüggetlen, a találatok kiemelve, kategórián belül is.
- Az adminisztráció „Adatok frissítése” gombja a régi bejegyzéseket hírré és kereshetővé teszi.

## 0.5.3

### Javítva

- A „Mire gondolsz” sáv a vezetéknév utáni első szót használja. Az előtagok (Dr., dr., Ifj., id., Prof.) kimaradnak.
- Edző csak a saját bejegyzéséhez, vagy még nem létező bejegyzéshez tölthet fel fájlt. Az admin bármelyikhez írhat.

## 0.5.2

### Hozzáadva

- Világos és sötét téma kapcsoló a fejlécben, a menü előtt. A választás a készüléken megmarad.
- A menü Megjelenés sora: Világos, Sötét vagy a telefon rendszere. Első indításkor a rendszer témája érvényes.

## 0.5.1

### Változtatva

- A bejegyzés szerkesztője alulról felcsúszó lap: arany gyűrűs profil, nagy szövegmező, színes médiaeszköztár és bordó közzététel gomb.
- A hírfolyam sávja keresztnévvel szólít meg, és fotó, videó vagy kamera választóval nyitja a szerkesztőt.
- A piszkozat helyben megmarad. Ha van szöveg vagy média, az elvetés megerősítést kér.

### Hozzáadva

- Arany kiegészítő szín, bordó átmenet a fő gombon, és a médiagombok saját színei világos és sötét módban.

## 0.5.0

### Hozzáadva

- A fejléc logója és a klubnév bárhonnan a hírfolyamra visz. A hírfolyamon a lista tetejére görget és frissít.
- Képes és videós bejegyzés: legfeljebb 10 kép és 1 videó, tömörítés, feltöltési százalék és megszakítás.
- Egyszeri figyelmeztetés: csak szülői hozzájárulással készült gyermekfotó vagy videó tölthető fel.
- Reakciók a pipa helyett: Like, szív, haha, wow, szomorú és Osu!. Rövid koppintás a Like-ot kapcsolja, hosszú nyomás a választósávot nyitja.
- Storage-szabályok: aktív tag olvashat, admin és edző tölthet fel, a szerző vagy az admin törölhet.

### Változtatva

- A bejegyzés csak akkor jelenik meg, ha minden fájl feltöltődött. Törléskor a Storage-fájlok is törlődnek.

## 0.4.0

### Változtatva

- A hírfolyam teljes szélességű fehér kártyákból áll, a cím alatt az edző és az admin a „Mire gondolsz?” sávból ír.
- A pipa pattanó animációval és haptikus visszajelzéssel azonnal megjelenik. A hosszú szöveg helyben nyílik ki, a linkek megnyithatók.
- A kártya alján a legutóbbi két hozzászólás látszik. A részleteken a hozzászólások buborékban vannak, alul rögzített beviteli sorral.
- Betöltéskor skeleton helyőrző jelenik meg. Az üres állapot és a hibák külön, pontos szöveggel jelennek meg.

### Javítva

- Bejegyzés törlésekor a pipák és a hozzászólások is törlődnek. A pipát a pipázó, a bejegyzés szerzője és az admin törölheti.

## 0.3.0

### Hozzáadva

- Hírfolyam a kitűzött bejegyzésekkel felül, lapozással és lehúzással frissítéssel.
- Bejegyzést admin és edző írhat, szerkeszthet és törölhet; admin bármelyiket kezelheti.
- Zöld pipa és hozzászólások. A számlálók Firestore count() aggregációval készülnek.
- Firestore-szabályok és index a `posts` gyűjteményre.

## 0.2.1

### Javítva

- Az edző csak sportoló vagy szülő fiókot módosíthat. Admin és edző dokumentumát csak admin írhatja.
- Jóváhagyás után a születési dátum a saját dokumentumban sem írható át. Pending állapotban még javítható.
- Létrehozáskor és saját módosításkor a dokumentum csak az ismert mezőket tartalmazhatja.
- A hiányzó mező nem utasítja el a szabályos összehasonlítást.

### Hozzáadva

- Firestore szabálytesztek a helyi emulátoron (`npm run test:rules`).

## 0.2.0

### Hozzáadva

- E-mailes bejelentkezés, regisztráció és jelszó-visszaállítás.
- Sportoló és szülő regisztráció; 18 év alatt figyelmeztetés, szülőnél gyermekkérések.
- Jóváhagyásra váró és elutasított fiók csak a várakozó képernyőt éri el.
- Admin és edző jóváhagyhat vagy elutasíthat; szülőt aktív sportolóhoz kapcsolhat.
- Szerepkört csak admin oszthat. Az útvonalak a fiók állapota szerint védettek.
- Firestore biztonsági szabályok a `users` gyűjteményre.

### Változtatva

- Világos módban az AppBar fehér, sötét bordó felirattal és ikonokkal.
- Sötét módban az AppBar a sötét felület színe, a felirat és az ikonok `#C4566B`.

## 0.1.0

- Projektváz, Material 3 téma, alap útvonalak és Firebase inicializálás.
