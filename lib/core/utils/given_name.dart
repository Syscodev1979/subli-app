/// Magyar névsorrend: a keresztnév a vezetéknév utáni első szó.
/// Az előtagok (Dr., dr., Ifj., id., Prof.) nem számítanak.
String givenName(String fullName) {
  const prefixes = {'dr', 'ifj', 'id', 'prof'};
  final words = [
    for (final word in fullName.trim().split(RegExp(r'\s+')))
      if (word.isNotEmpty) word,
  ];
  var start = 0;
  while (start < words.length &&
      prefixes.contains(words[start].replaceAll('.', '').toLowerCase())) {
    start++;
  }
  final name = words.sublist(start);
  if (name.isEmpty) return '';
  if (name.length == 1) return name.first;
  return name[1];
}
