/// E-mail és jelszó alapú belépés. A profiladat a [UserRepository]-ban van.
abstract class AuthRepository {
  Stream<String?> watchUserId();

  /// A bejelentkezett fiók, tokenfrissítéskor is. Kijelentkezve null.
  Stream<({String id, String? email, bool emailVerified})?> watchIdentity();

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

  Future<void> sendEmailVerification();

  /// Újratölti a felhasználót, hogy az e-mail-megerősítés látszódjon.
  Future<void> reloadCurrentUser();
}
