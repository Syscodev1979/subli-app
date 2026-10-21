import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/widgets/splash_screen.dart';
import '../features/admin/presentation/admin_screen.dart';
import '../features/auth/data/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/pending_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/calendar/presentation/calendar_screen.dart';
import '../features/chat/presentation/chat_screen.dart';
import '../features/feed/presentation/feed_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import 'auth_redirect.dart';
import 'constants.dart';

/// A go_router a bejelentkezés és a fiók állapota szerint irányít.
final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authGateProvider, (_, _) {
    refresh.value++;
  });
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(authGateProvider);
      return authRedirect(
        phase: authPhaseOf(session),
        canReviewMembers: canReviewMembersOf(session),
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.pending,
        builder: (context, state) => const PendingScreen(),
      ),
      GoRoute(
        path: AppRoutes.feed,
        builder: (context, state) => const FeedScreen(),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.calendar,
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});
