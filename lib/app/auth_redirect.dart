import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/domain/auth_session.dart';
import '../features/auth/domain/user_status.dart';
import 'constants.dart';

/// A router döntéséhez elég ennyi, a képernyők a részletes munkamenetet nézik.
enum AuthPhase { loading, signedOut, profileMissing, pending, rejected, active }

AuthPhase authPhaseOf(AsyncValue<AuthSession> session) {
  if (session.isLoading || session.hasError) return AuthPhase.loading;
  return switch (session.requireValue) {
    AuthSignedOut() => AuthPhase.signedOut,
    AuthProfileMissing() => AuthPhase.profileMissing,
    AuthSignedIn(:final user) when user.status == UserStatus.pending =>
      AuthPhase.pending,
    AuthSignedIn(:final user) when user.status == UserStatus.rejected =>
      AuthPhase.rejected,
    AuthSignedIn() => AuthPhase.active,
  };
}

bool canReviewMembersOf(AsyncValue<AuthSession> session) {
  final value = session.asData?.value;
  return value is AuthSignedIn && value.user.role.canReviewMembers;
}

/// Hova vigyen a router. `null`, ha a jelenlegi útvonal maradhat.
String? authRedirect({
  required AuthPhase phase,
  required bool canReviewMembers,
  required String location,
}) {
  switch (phase) {
    case AuthPhase.loading:
    case AuthPhase.profileMissing:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case AuthPhase.signedOut:
      if (location == AppRoutes.login || location == AppRoutes.register) {
        return null;
      }
      return AppRoutes.login;
    case AuthPhase.pending:
    case AuthPhase.rejected:
      return location == AppRoutes.pending ? null : AppRoutes.pending;
    case AuthPhase.active:
      const awayFromApp = {
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.pending,
        AppRoutes.splash,
      };
      if (awayFromApp.contains(location)) return AppRoutes.feed;
      if (location == AppRoutes.admin && !canReviewMembers) {
        return AppRoutes.feed;
      }
      return null;
  }
}
