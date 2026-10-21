/// A Firebase Storage letöltési URL-jéből az objektum útvonala.
String? storageObjectPath(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null) return null;
  const marker = '/o/';
  final index = uri.path.indexOf(marker);
  if (index < 0) return null;
  final encoded = uri.path.substring(index + marker.length);
  if (encoded.isEmpty) return null;
  return Uri.decodeComponent(encoded);
}
