/// Ékezet nélküli, kisbetűs alak kereséshez.
String foldHu(String value) {
  const pairs = {
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
  final buffer = StringBuffer();
  for (final char in value.toLowerCase().split('')) {
    buffer.write(pairs[char] ?? char);
  }
  return buffer.toString();
}

bool containsFolded(String source, String query) {
  final needle = foldHu(query.trim());
  if (needle.isEmpty) return true;
  return foldHu(source).contains(needle);
}
