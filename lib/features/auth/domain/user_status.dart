/// A fiók állapota. Új regisztráció mindig [pending].
enum UserStatus {
  pending('pending'),
  active('active'),
  rejected('rejected');

  const UserStatus(this.value);

  /// Firestore-ban tárolt érték.
  final String value;

  static UserStatus parse(String value) {
    for (final status in UserStatus.values) {
      if (status.value == value) return status;
    }
    throw FormatException('Unknown status: $value');
  }

  bool get isBlocked =>
      this == UserStatus.pending || this == UserStatus.rejected;
}
