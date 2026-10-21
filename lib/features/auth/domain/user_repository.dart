import 'app_user.dart';
import 'user_role.dart';
import 'user_status.dart';

/// A `users` gyűjtemény írása és olvasása.
abstract class UserRepository {
  Stream<AppUser?> watchUser(String id);

  Future<void> createUser(AppUser user);

  Stream<List<AppUser>> watchByStatus(UserStatus status);

  Stream<List<AppUser>> watchActiveAthletes();

  /// Jóváhagyás. A [assignedRole] csak admin hívásból érkezik.
  /// Szülőnél a [childIds] bekerül a szülőhöz, a gyermek `parentIds` mezőjébe
  /// pedig a szülő azonosítója.
  Future<void> approveUser({
    required String userId,
    required UserRole currentRole,
    UserRole? assignedRole,
    List<String> childIds = const [],
  });

  Future<void> rejectUser(String userId);
}
