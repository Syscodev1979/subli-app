import '../../../app/club_config.dart';

/// Szerepkör a `users` dokumentumban.
enum UserRole {
  admin('admin'),
  coach('coach'),
  athlete('athlete'),
  parent('parent'),
  member('member');

  const UserRole(this.value);

  /// Firestore-ban tárolt érték.
  final String value;

  static UserRole parse(String value) {
    for (final role in UserRole.values) {
      if (role.value == value) return role;
    }
    throw FormatException('Unknown role: $value');
  }

  /// Jóváhagyás. Egyszerű tagságnál csak az admin, különben az edző is.
  bool get canReviewMembers =>
      this == UserRole.admin ||
      (!ClubConfig.enforceSimpleMembership && this == UserRole.coach);

  /// Bejegyzést egyszerű tagságnál csak az admin írhat, különben az edző is.
  bool get canWritePosts => canReviewMembers;

  /// Edzői szerep kiosztása. Az admin szerep az appból nem adható.
  bool get canAssignRoles => this == UserRole.admin;

  /// A felületen választható szerepek. Az admin nincs köztük.
  static const List<UserRole> assignable = [
    UserRole.athlete,
    UserRole.parent,
    UserRole.coach,
  ];

  /// 18 év feletti klubban a szülő nem választható. A [assignable] lista
  /// változatlan, ha [ClubConfig.enforceAdultsOnly] hamis.
  static List<UserRole> get assignableRoles => ClubConfig.enforceAdultsOnly
      ? const [UserRole.athlete, UserRole.coach]
      : assignable;
}
