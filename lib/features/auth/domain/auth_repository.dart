/// E-mail és jelszó alapú belépés. A profiladat a [UserRepository]-ban van.
abstract class AuthRepository {
  Stream<String?> watchUserId();

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  /// Új Firebase-fiók. A visszaadott e-mail a hitelesítés kanonikus címe.
  Future<({String id, String email})> createAccount({
    required String email,
    required String password,
  });

  /// Félbeszakadt regisztrációnál a már létrejött fiók törlése.
  Future<void> deleteCurrentAccount();

  Future<void> sendPasswordResetEmail(String email);
}
