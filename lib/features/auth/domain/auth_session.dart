import 'app_user.dart';

/// A bejelentkezés és a profilbetöltés együttese, a router számára.
sealed class AuthSession {
  const AuthSession();
}

final class AuthSignedOut extends AuthSession {
  const AuthSignedOut();
}

/// Van Firebase-felhasználó, de még nincs `users` dokumentum.
final class AuthProfileMissing extends AuthSession {
  const AuthProfileMissing();
}

final class AuthSignedIn extends AuthSession {
  const AuthSignedIn(
    this.user, {
    this.emailVerified = true,
    this.authEmail,
  });

  final AppUser user;

  /// A Firebase Auth token `email_verified` értéke.
  final bool emailVerified;

  /// A Firebase Auth e-mailje. Ha nincs külön megadva, a profil e-mailje.
  final String? authEmail;

  String get identityEmail => authEmail ?? user.email;
}
