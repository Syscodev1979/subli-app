import '../domain/app_user.dart';
import '../domain/auth_repository.dart';
import '../domain/child_request.dart';
import '../domain/user_repository.dart';
import '../domain/user_role.dart';
import '../domain/user_status.dart';

/// Firebase-fiók és `users` dokumentum együttesen, pending állapottal.
class AccountRegistrar {
  AccountRegistrar(this._auth, this._users);

  final AuthRepository _auth;
  final UserRepository _users;

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required UserRole role,
    DateTime? birthDate,
    List<ChildRequest> childRequests = const [],
  }) async {
    final account = await _auth.createAccount(email: email, password: password);
    try {
      await _users.createUser(
        AppUser(
          id: account.id,
          name: name.trim(),
          email: account.email,
          role: role,
          birthDate: birthDate,
          photoUrl: null,
          status: UserStatus.pending,
          childIds: const [],
          parentIds: const [],
          childRequests: childRequests,
          createdAt: DateTime.now(),
        ),
      );
    } catch (error) {
      try {
        await _auth.deleteCurrentAccount();
      } catch (_) {
        // A profilírás hibája a fontos; a fiók törlése másodlagos.
      }
      rethrow;
    }
  }
}
