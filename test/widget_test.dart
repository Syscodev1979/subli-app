import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastroyal_karate_app/features/auth/data/auth_providers.dart';
import 'package:gastroyal_karate_app/features/auth/domain/app_user.dart';
import 'package:gastroyal_karate_app/features/auth/domain/auth_session.dart';
import 'package:gastroyal_karate_app/features/auth/domain/user_role.dart';
import 'package:gastroyal_karate_app/features/auth/domain/user_status.dart';
import 'package:gastroyal_karate_app/features/feed/data/feed_providers.dart';
import 'package:gastroyal_karate_app/main.dart';

import 'fake_post_repository.dart';

void main() {
  testWidgets('A hírfolyam fejlécén megjelenik a klub neve', (tester) async {
    await _pumpApp(tester, AuthSignedIn(_activeAthlete()));

    expect(find.text('Gastroyal Karate SE'), findsOneWidget);
    expect(find.byTooltip('Menü'), findsOneWidget);
    expect(find.text('Még nincs bejegyzés.'), findsOneWidget);
    expect(find.byTooltip('Új bejegyzés'), findsNothing);

    final appBarTheme = Theme.of(tester.element(find.byType(AppBar)))
        .appBarTheme;
    expect(appBarTheme.backgroundColor, const Color(0xFFFFFFFF));
    expect(appBarTheme.foregroundColor, const Color(0xFF6B1E2E));
    expect(appBarTheme.elevation, 0);
  });

  testWidgets('Edzőnek megjelenik az új bejegyzés gomb', (tester) async {
    await _pumpApp(tester, AuthSignedIn(_activeUser(role: UserRole.coach)));

    expect(find.byTooltip('Új bejegyzés'), findsOneWidget);
    await tester.tap(find.byTooltip('Új bejegyzés'));
    await tester.pumpAndSettle();

    expect(find.text('Kitűzés'), findsOneWidget);
    expect(find.text('Közzététel'), findsOneWidget);
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
      overrides: [
        authGateProvider.overrideWithValue(AsyncData(session)),
        postRepositoryProvider.overrideWithValue(const FakePostRepository()),
      ],
      child: const GastroyalApp(),
    ),
  );
  await tester.pumpAndSettle();
}

AppUser _activeAthlete() => _activeUser();

AppUser _activeUser({UserRole role = UserRole.athlete}) {
  return AppUser(
    id: 'athlete-1',
    name: 'Teszt Sportoló',
    email: 'teszt@example.com',
    role: role,
    birthDate: DateTime(2000, 1, 1),
    photoUrl: null,
    status: UserStatus.active,
    childIds: const [],
    parentIds: const [],
    childRequests: const [],
    createdAt: DateTime(2026, 1, 1),
  );
}
