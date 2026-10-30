import 'package:firebase_auth/firebase_auth.dart';

import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final FirebaseAuth _auth;

  @override
  Stream<String?> watchUserId() {
    return _auth.authStateChanges().map((user) => user?.uid);
  }

  @override
  Stream<({String id, String? email, bool emailVerified})?> watchIdentity() {
    return _auth.userChanges().map((user) {
      if (user == null) return null;
      return (
        id: user.uid,
        email: user.email,
        emailVerified: user.emailVerified,
      );
    });
  }

  @override
  Future<void> signIn({required String email, required String password}) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<({String id, String email})> createAccount({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Account was created without a user id.',
      );
    }
    return (id: user.uid, email: user.email ?? email.trim());
  }

  @override
  Future<void> deleteCurrentAccount() async {
    await _auth.currentUser?.delete();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  @override
  Future<void> reloadCurrentUser() async {
    await _auth.currentUser?.reload();
  }
}
