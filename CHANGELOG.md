# Változásnapló

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
