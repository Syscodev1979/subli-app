/// Szerepkör a `users` dokumentumban.
enum UserRole {
  admin('admin'),
  coach('coach'),
  athlete('athlete'),
  parent('parent');

  const UserRole(this.value);

  /// Firestore-ban tárolt érték.
  final String value;

  static UserRole parse(String value) {
    for (final role in UserRole.values) {
      if (role.value == value) return role;
    }
    throw FormatException('Unknown role: $value');
  }

  /// Jóváhagyási lista: admin és edző.
  bool get canReviewMembers => this == UserRole.admin || this == UserRole.coach;

  /// Edzői vagy admin szerep kiosztása.
  bool get canAssignRoles => this == UserRole.admin;
}
