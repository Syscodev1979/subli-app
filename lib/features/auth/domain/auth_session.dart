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
  const AuthSignedIn(this.user);

  final AppUser user;
}
