import 'child_request.dart';
import 'user_role.dart';
import 'user_status.dart';

/// Egy klubtag a Firestore `users` gyűjteményében.
class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.birthDate,
    required this.photoUrl,
    required this.status,
    required this.childIds,
    required this.parentIds,
    required this.childRequests,
    required this.createdAt,
    this.beltRank,
    this.requestedRole,
    this.groupIds = const [],
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DateTime? birthDate;
  final String? photoUrl;
  final UserStatus status;
  final List<String> childIds;
  final List<String> parentIds;

  /// Szülő regisztrációjakor megadott gyermekek. Az összekapcsolást edző végzi.
  final List<ChildRequest> childRequests;
  final DateTime createdAt;

  /// Övfokozat kulcsa, például `kyu5`. Csak edző és admin írhatja.
  final String? beltRank;

  /// Jelentkezéskor kért szerep. Jelenleg csak `coach` lehet, és csak létrehozáskor.
  final String? requestedRole;

  /// Edzéscsoportok azonosítói. Csak admin írhatja.
  final List<String> groupIds;

  bool get requestedCoach => requestedRole == 'coach';
}
