String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Add meg az e-mail-címet.';
  final valid = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  if (!valid) return 'Érvénytelen e-mail-cím.';
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.length < 6) {
    return 'A jelszónak legalább 6 karakternek kell lennie.';
  }
  return null;
}

String? validateName(String? value) {
  final name = value?.trim() ?? '';
  if (name.length < 2) return 'Add meg a teljes nevet.';
  return null;
}
