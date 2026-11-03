import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:subli_app/features/auth/data/auth_providers.dart';
import 'package:subli_app/features/auth/domain/app_user.dart';
import 'package:subli_app/features/auth/domain/auth_session.dart';
import 'package:subli_app/features/auth/domain/user_role.dart';
import 'package:subli_app/features/auth/domain/user_status.dart';
import 'package:subli_app/features/chat/data/chat_providers.dart';
import 'package:subli_app/features/feed/data/feed_providers.dart';
import 'package:subli_app/main.dart';

import 'fake_chat_repository.dart';
import 'fake_post_repository.dart';

void main() {
  testWidgets('A hírfolyam fejlécén megjelenik a klub neve', (tester) async {
    await _pumpApp(tester, AuthSignedIn(_activeAthlete()));

    expect(find.text('Subli – lovas közösségi app'), findsOneWidget);
    expect(find.byTooltip('Menü'), findsOneWidget);
    expect(find.text('Keresés a Hírfolyamban…'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('club-app-bar')),
        matching: find.byIcon(Icons.search),
      ),
      findsNothing,
    );
    expect(
      find.text('Még nincs bejegyzés. Hamarosan itt lesznek a klub hírei!'),
      findsOneWidget,
    );
    expect(find.text('Mire gondolsz?'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);

    final appBarTheme = Theme.of(tester.element(find.byType(AppBar)))
        .appBarTheme;
    expect(appBarTheme.backgroundColor, const Color(0xFFFFFFFF));
    expect(appBarTheme.foregroundColor, const Color(0xFF6B1E2E));
    expect(appBarTheme.elevation, 0);
  });

  testWidgets('Edző a Mire gondolsz sávból ír bejegyzést', (tester) async {
    await _pumpApp(
      tester,
      AuthSignedIn(_activeUser(role: UserRole.coach, name: 'Kovács Anna')),
    );

    expect(find.text('Keresés a Hírfolyamban…'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('club-app-bar')),
        matching: find.byIcon(Icons.search),
      ),
      findsNothing,
    );
    expect(find.text('Mire gondolsz, Anna?'), findsOneWidget);
    expect(find.text('Fotó'), findsOneWidget);
    expect(find.text('Videó'), findsOneWidget);
    expect(find.text('Dokumentum'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    await tester.tap(find.text('Mire gondolsz, Anna?'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Kitűzés'), findsOneWidget);
    expect(find.text('Közzététel'), findsOneWidget);
    expect(find.text('Új bejegyzés'), findsOneWidget);
  });

  testWidgets('Kijelentkezve a bejelentkezés látszik', (tester) async {
    await _pumpApp(tester, const AuthSignedOut());

    expect(find.text('Belépés'), findsOneWidget);
    expect(find.text('Elfelejtett jelszó?'), findsOneWidget);
  });
}

Future<void> _pumpApp(WidgetTester tester, AuthSession session) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authGateProvider.overrideWithValue(AsyncData(session)),
        postRepositoryProvider.overrideWithValue(const FakePostRepository()),
        chatRepositoryProvider.overrideWithValue(const FakeChatRepository()),
      ],
      child: const SubliApp(),
    ),
  );
  await tester.pumpAndSettle();
}

AppUser _activeAthlete() => _activeUser();

AppUser _activeUser({
  UserRole role = UserRole.athlete,
  String name = 'Teszt Sportoló',
}) {
  return AppUser(
    id: 'athlete-1',
    name: name,
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
