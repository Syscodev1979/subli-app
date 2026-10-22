/// Gyakori töltelékszavak, ékezet nélkül. Ezek nem kerülnek a keresőlistába.
const searchStopWords = <String>{
  'a',
  'az',
  'es',
  'de',
  'hogy',
  'is',
  'egy',
  'meg',
  'nem',
  'van',
  'vagy',
  'ha',
  'mint',
  'csak',
  'mar',
  'ez',
  'ezt',
  'azt',
  'mert',
  'pedig',
  'sem',
  'se',
  'volt',
  'lesz',
  'ami',
  'aki',
  'itt',
  'ott',
  'nagyon',
  'en',
  'te',
  'mi',
  'ok',
  'neki',
  'nekem',
  'vagyok',
  'vannak',
  'nincs',
  'ezen',
  'azon',
  'ennek',
  'annak',
  'illetve',
  'valamint',
  'azonban',
  'ezert',
  'ugyanis',
};

const _accent = {
  'á': 'a',
  'é': 'e',
  'í': 'i',
  'ó': 'o',
  'ö': 'o',
  'ő': 'o',
  'ú': 'u',
  'ü': 'u',
  'ű': 'u',
};

final _wordPattern = RegExp(r'[\p{L}\p{N}]+', unicode: true);

/// Kisbetűs, ékezet nélküli alak. A karakterek száma nem változik.
String foldAccents(String value) {
  final buffer = StringBuffer();
  for (final rune in value.runes) {
    final char = String.fromCharCode(rune);
    buffer.write(_accent[char] ?? char);
  }
  return buffer.toString();
}

/// A bejegyzés szövegéből készült keresőszavak.
///
/// Kisbetűs, ékezet nélküli, egyedi szavak. Legalább 2 karakter, legfeljebb
/// [maxWords] darab, a töltelékszavak nélkül.
List<String> searchKeywords(String text, {int maxWords = 200}) {
  final seen = <String>{};
  final words = <String>[];
  for (final match in _wordPattern.allMatches(text)) {
    final folded = foldAccents(match.group(0)!.toLowerCase());
    if (folded.length < 2 || searchStopWords.contains(folded)) continue;
    if (!seen.add(folded)) continue;
    words.add(folded);
    if (words.length >= maxWords) break;
  }
  return words;
}

/// A keresőmező kifejezése ugyanazzal a szabállyal, a gépelés sorrendjében.
List<String> searchTerms(String query) => searchKeywords(query);

/// A [terms] második szavától a szövegben kell szerepelniük.
/// Az első szót a Firestore `array-contains` szűri.
bool matchesExtraTerms(String text, List<String> terms) {
  if (terms.length < 2) return true;
  final folded = foldAccents(text.toLowerCase());
  for (final term in terms.skip(1)) {
    if (!folded.contains(term)) return false;
  }
  return true;
}

/// Kiemelési tartományok az eredeti szövegben. A találat ékezetfüggetlen.
List<({int start, int end})> highlightRanges(String text, List<String> terms) {
  if (text.isEmpty || terms.isEmpty) return const [];
  final folded = foldAccents(text.toLowerCase());
  final ranges = <({int start, int end})>[];
  for (final term in terms) {
    if (term.isEmpty) continue;
    var from = 0;
    while (from < folded.length) {
      final index = folded.indexOf(term, from);
      if (index < 0) break;
      ranges.add((start: index, end: index + term.length));
      from = index + term.length;
    }
  }
  if (ranges.isEmpty) return const [];
  ranges.sort((a, b) => a.start.compareTo(b.start));
  final merged = <({int start, int end})>[ranges.first];
  for (final range in ranges.skip(1)) {
    final last = merged.last;
    if (range.start <= last.end) {
      merged[merged.length - 1] = (
        start: last.start,
        end: range.end > last.end ? range.end : last.end,
      );
    } else {
      merged.add(range);
    }
  }
  return merged;
}
