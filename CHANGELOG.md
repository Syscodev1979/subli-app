# Változásnapló

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
