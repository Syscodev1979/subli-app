import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/auth_repository.dart';
import '../domain/auth_session.dart';
import '../domain/user_repository.dart';
import 'account_registrar.dart';
import 'firebase_auth_repository.dart';
import 'firestore_user_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(FirebaseAuth.instance);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirestoreUserRepository(FirebaseFirestore.instance);
});

final accountRegistrarProvider = Provider<AccountRegistrar>((ref) {
  return AccountRegistrar(
    ref.watch(authRepositoryProvider),
    ref.watch(userRepositoryProvider),
  );
});

/// Először a Firebase Auth felhasználó, utána a Firestore profil.
final authGateProvider = StreamProvider<AuthSession>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final userRepository = ref.watch(userRepositoryProvider);

  return authRepository.watchUserId().asyncExpand((userId) {
    if (userId == null) {
      return Stream<AuthSession>.value(const AuthSignedOut());
    }
    return userRepository.watchUser(userId).map((user) {
      if (user == null) return const AuthProfileMissing();
      return AuthSignedIn(user);
    });
  });
});
