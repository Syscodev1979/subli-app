/// A saját verzió a minimumhoz és a legújabbhoz képest.
enum VersionPrompt { none, optional, required }

/// `current` kisebb, mint a [minVersion]: kötelező frissítés.
/// Csak a [latestVersion]-nél kisebb: finom, bezárható jelzés.
/// Hiányzó vagy olvashatatlan érték nem blokkol.
VersionPrompt versionPrompt({
  required String current,
  String? minVersion,
  String? latestVersion,
}) {
  if (_isOlder(current, minVersion)) return VersionPrompt.required;
  if (_isOlder(current, latestVersion)) return VersionPrompt.optional;
  return VersionPrompt.none;
}

bool _isOlder(String current, String? required) {
  final target = required?.trim();
  if (target == null || target.isEmpty) return false;
  return compareVersionNames(current, target) < 0;
}

/// A `+build` részt nem nézi. Hiányzó tag nulla.
int compareVersionNames(String left, String right) {
  final a = _parts(left);
  final b = _parts(right);
  for (var i = 0; i < 3; i++) {
    final diff = a[i] - b[i];
    if (diff != 0) return diff;
  }
  return 0;
}

List<int> _parts(String raw) {
  final head = raw.split('+').first.trim();
  final bits = head.split('.');
  return [
    for (var i = 0; i < 3; i++)
      i < bits.length ? int.tryParse(bits[i]) ?? 0 : 0,
  ];
}
