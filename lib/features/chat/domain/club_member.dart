import '../../auth/domain/user_role.dart';

/// A tagkeresőben látható aktív klubtag. A `members` gyűjteményből jön.
class ClubMember {
  const ClubMember({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.role,
    required this.isMinor,
    required this.parentIds,
    this.beltRank,
  });

  final String id;
  final String name;
  final String? photoUrl;
  final UserRole role;
  final bool isMinor;
  final List<String> parentIds;
  final String? beltRank;

  /// A tagkereső címkéje.
  String get roleLabel => switch (role) {
    UserRole.admin => 'Admin',
    UserRole.coach => 'Edző',
    UserRole.athlete => 'Sportoló',
    UserRole.parent => 'Szülő',
  };
}
