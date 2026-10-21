import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastroyal_karate_app/features/auth/data/auth_providers.dart';
import 'package:gastroyal_karate_app/features/auth/domain/app_user.dart';
import 'package:gastroyal_karate_app/features/auth/domain/auth_session.dart';
import 'package:gastroyal_karate_app/features/auth/domain/user_role.dart';
import 'package:gastroyal_karate_app/features/auth/domain/user_status.dart';
import 'package:gastroyal_karate_app/main.dart';

void main() {
  testWidgets('A hírfolyam fejlécén megjelenik a klub neve', (tester) async {
    await _pumpApp(tester, AuthSignedIn(_activeAthlete()));

    expect(find.text('Gastroyal Karate SE'), findsOneWidget);
    expect(find.byTooltip('Menü'), findsOneWidget);

    final appBarTheme = Theme.of(tester.element(find.byType(AppBar)))
        .appBarTheme;
    expect(appBarTheme.backgroundColor, const Color(0xFFFFFFFF));
    expect(appBarTheme.foregroundColor, const Color(0xFF6B1E2E));
    expect(appBarTheme.elevation, 0);
  });

  testWidgets('Kijelentkezve a bejelentkezés látszik', (tester) async {
    await _pumpApp(tester, const AuthSignedOut());

    expect(find.text('Bejelentkezés'), findsWidgets);
    expect(find.text('Elfelejtett jelszó'), findsOneWidget);
  });
}

Future<void> _pumpApp(WidgetTester tester, AuthSession session) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authGateProvider.overrideWithValue(AsyncData(session))],
      child: const GastroyalApp(),
    ),
  );
  await tester.pump();
  await tester.pump();
}

AppUser _activeAthlete() {
  return AppUser(
    id: 'athlete-1',
    name: 'Teszt Sportoló',
    email: 'teszt@example.com',
    role: UserRole.athlete,
    birthDate: DateTime(2000, 1, 1),
    photoUrl: null,
    status: UserStatus.active,
    childIds: const [],
    parentIds: const [],
    childRequests: const [],
    createdAt: DateTime(2026, 1, 1),
  );
}
