import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/app/constants.dart';
import 'package:subli_app/app/theme.dart';
import 'package:subli_app/app/theme_controller.dart';
import 'package:subli_app/app/theme_preference.dart';
import 'package:subli_app/core/widgets/theme_switch.dart';
import 'package:subli_app/features/auth/data/auth_providers.dart';
import 'package:subli_app/features/auth/domain/app_user.dart';
import 'package:subli_app/features/auth/domain/auth_session.dart';
import 'package:subli_app/features/auth/domain/user_role.dart';
import 'package:subli_app/features/auth/domain/user_status.dart';
import 'package:subli_app/features/chat/data/chat_providers.dart';
import 'package:subli_app/features/feed/data/feed_providers.dart';
import 'package:subli_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_chat_repository.dart';
import 'fake_post_repository.dart';

void main() {
  testWidgets('koppintásra sötét téma lesz, és az értesítés megjelenik', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpFeed(tester);

    expect(
      find.byTooltip(ThemePreference.semantics(dark: false)),
      findsOneWidget,
    );
    expect(_appBarColor(tester), const Color(0xFFFFFFFF));

    await tester.tap(find.byType(ThemeSwitch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(ThemePreference.snackBar(dark: true)), findsOneWidget);
    await tester.pumpAndSettle();
    expect(_appBarColor(tester), AppColors.darkSurface);
    expect(
      find.byTooltip(ThemePreference.semantics(dark: true)),
      findsOneWidget,
    );
    expect(
      tester
          .widget<AnnotatedRegion<SystemUiOverlayStyle>>(
            find.byType(AnnotatedRegion<SystemUiOverlayStyle>).first,
          )
          .value
          .statusBarIconBrightness,
      Brightness.light,
    );
  });

  testWidgets('a választás újraindítás után is megmarad', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await _pumpFeed(tester);
    await tester.tap(find.byType(ThemeSwitch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ThemeController.storageKey), 'dark');

    await tester.pumpWidget(const SizedBox.shrink());
    await _pumpFeed(tester);
    expect(_appBarColor(tester), AppColors.darkSurface);
    expect(
      find.byTooltip(ThemePreference.semantics(dark: true)),
      findsOneWidget,
    );
  });

  testWidgets('a Rendszer szerint visszaállítja a telefon témáját', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'theme_preference': 'dark'});
    await _pumpFeed(tester);
    expect(_appBarColor(tester), AppColors.darkSurface);

    await tester.tap(find.byTooltip('Menü'));
    await tester.pumpAndSettle();
    expect(_radioSelected(tester, 'Sötét'), isTrue);

    await tester.tap(find.text('Rendszer szerint'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ThemeController.storageKey), 'system');
    expect(_radioSelected(tester, 'Rendszer szerint'), isTrue);
    expect(_appBarColor(tester), const Color(0xFFFFFFFF));
    expect(
      find.byTooltip(ThemePreference.semantics(dark: false)),
      findsOneWidget,
    );
  });

  testWidgets('szűk fejlécen a klubnév rövidül, a kapcsoló teljes marad', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(300, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    await _pumpFeed(tester);

    expect(find.text('Subli'), findsOneWidget);
    expect(find.text(AppInfo.clubName), findsNothing);
    expect(tester.getSize(find.byType(ThemeSwitch)), const Size(64, 32));
  });

  testWidgets('világos kapcsoló golden', (tester) async {
    await _pumpSwitch(tester, dark: false);
    await expectLater(
      find.byType(ThemeSwitch),
      matchesGoldenFile('goldens/theme_switch_light.png'),
    );
  });

  testWidgets('sötét kapcsoló golden', (tester) async {
    await _pumpSwitch(tester, dark: true);
    await expectLater(
      find.byType(ThemeSwitch),
      matchesGoldenFile('goldens/theme_switch_dark.png'),
    );
  });
}

Future<void> _pumpFeed(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authGateProvider.overrideWithValue(AsyncData(AuthSignedIn(_athlete()))),
        postRepositoryProvider.overrideWithValue(const FakePostRepository()),
        chatRepositoryProvider.overrideWithValue(const FakeChatRepository()),
      ],
      child: const SubliApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpSwitch(WidgetTester tester, {required bool dark}) async {
  tester.view.physicalSize = const Size(96, 48);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: const Scaffold(
          body: Center(
            child: RepaintBoundary(child: ThemeSwitch()),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color? _appBarColor(WidgetTester tester) {
  return Theme.of(tester.element(find.byType(AppBar)))
      .appBarTheme
      .backgroundColor;
}

bool _radioSelected(WidgetTester tester, String label) {
  return tester.widget<ListTile>(find.widgetWithText(ListTile, label)).selected;
}

AppUser _athlete() {
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
