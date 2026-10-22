/// Magyar névsorrendben a keresztnév a teljes név utolsó szava.
String givenName(String fullName) {
  final trimmed = fullName.trim();
  if (trimmed.isEmpty) return '';
  return trimmed.split(RegExp(r'\s+')).last;
}
