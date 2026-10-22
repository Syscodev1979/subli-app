import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastroyal_karate_app/app/constants.dart';
import 'package:gastroyal_karate_app/app/router.dart';
import 'package:gastroyal_karate_app/app/theme.dart';
import 'package:gastroyal_karate_app/features/auth/data/auth_providers.dart';
import 'package:gastroyal_karate_app/features/auth/domain/app_user.dart';
import 'package:gastroyal_karate_app/features/auth/domain/auth_session.dart';
import 'package:gastroyal_karate_app/features/auth/domain/user_role.dart';
import 'package:gastroyal_karate_app/features/auth/domain/user_status.dart';
import 'package:gastroyal_karate_app/features/feed/data/feed_providers.dart';
import 'package:gastroyal_karate_app/features/feed/presentation/press_scale.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_post_repository.dart';

void main() {
  testWidgets('a szerkesztő világos módban levegős, a rövid szöveg nagy', (
    tester,
  ) async {
    await _openComposer(tester, ThemeMode.light);

    expect(find.text('Új bejegyzés'), findsOneWidget);
    expect(
      find.text('Oszd meg a klub híreit, eredményeit, gondolataidat…'),
      findsOneWidget,
    );
    expect(find.text('Gastroyal Karate SE · minden tag'), findsOneWidget);
    expect(find.text('5000'), findsOneWidget);
    expect(_publishButton(tester).onTap, isNull);
    expect(_field(tester).style?.fontSize, 24);

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.pump();

    expect(_field(tester).style?.fontSize, 24);
    expect(_publishButton(tester).onTap, isNotNull);
    expect(find.text('4997'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'a' * 121);
    await tester.pump();
    expect(_field(tester).style?.fontSize, 18);

    final sheet = tester.widget<Material>(
      find.byKey(const Key('composer-sheet')),
    );
    expect(sheet.color, AppColors.feedCard);
    expect(
      sheet.borderRadius,
      const BorderRadius.vertical(top: Radius.circular(24)),
    );
  });

  testWidgets('sötét módban a lap sötét felület', (tester) async {
    await _openComposer(tester, ThemeMode.dark);

    final sheet = tester.widget<Material>(
      find.byKey(const Key('composer-sheet')),
    );
    expect(sheet.color, AppColors.feedDarkCard);
    expect(find.text('Közzététel'), findsOneWidget);
  });

  testWidgets('1.3-as betűméretnél a Kamera felirat egy sorban marad', (
    tester,
  ) async {
    _usePhoneSurface(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openComposer(tester, ThemeMode.light);

    expect(tester.takeException(), isNull);
    final labels = tester.widgetList<Text>(find.text('Kamera'));
    expect(labels, isNotEmpty);
    for (final label in labels) {
      expect(label.maxLines, 1);
      expect(label.softWrap, isFalse);
    }
  });

  testWidgets('a mégse megerősítést kér, ha van szöveg', (tester) async {
    await _openComposer(tester, ThemeMode.light);
    await tester.enterText(find.byType(TextField), 'Piszkozat');
    await tester.pump();

    await tester.tap(find.byTooltip('Mégse'));
    await tester.pumpAndSettle();

    expect(find.text('Elveted a bejegyzést?'), findsOneWidget);
    expect(find.text('Elvetés'), findsOneWidget);
    await tester.tap(find.text('Folytatom a szerkesztést'));
    await tester.pumpAndSettle();
    expect(find.text('Új bejegyzés'), findsOneWidget);

    await tester.tap(find.byTooltip('Mégse'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Elvetés'));
    await tester.pumpAndSettle();
    expect(find.text('Új bejegyzés'), findsNothing);
  });

  testWidgets('a piszkozatot újranyitáskor felajánlja', (tester) async {
    await _openComposer(tester, ThemeMode.light, draft: 'Tegnapi piszkozat');

    expect(find.text('Folytatod a piszkozatot?'), findsOneWidget);
    await tester.tap(find.text('Folytatom'));
    await tester.pumpAndSettle();
    expect(find.text('Tegnapi piszkozat'), findsOneWidget);
  });

  testWidgets('sikeres közzététel után jelzés és a lap bezárul', (
    tester,
  ) async {
    await _openComposer(tester, ThemeMode.light);
    await tester.enterText(find.byType(TextField), 'Elértük az aranyat.');
    await tester.pump();
    await tester.tap(find.text('Közzététel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text('Bejegyzés közzétéve'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Új bejegyzés'), findsNothing);
    expect(find.text('Bejegyzés közzétéve'), findsOneWidget);
  });

  testWidgets('a limit 90%-ánál a számláló arany, túllépésnél piros', (
    tester,
  ) async {
    await _openComposer(tester, ThemeMode.light);
    await tester.enterText(find.byType(TextField), 'a' * 4500);
    await tester.pump();
    expect(tester.widget<Text>(find.text('500')).style?.color, AppColors.gold);

    await tester.enterText(find.byType(TextField), 'a' * 5001);
    await tester.pump();
    final over = tester.widget<Text>(find.text('-1'));
    expect(
      over.style?.color,
      Theme.of(tester.element(find.byType(TextField))).colorScheme.error,
    );
    expect(_publishButton(tester).onTap, isNull);
  });

  testWidgets('világos szerkesztő golden', (tester) async {
    _usePhoneSurface(tester);
    await _openComposer(tester, ThemeMode.light);
    await expectLater(
      find.byKey(const Key('composer-sheet')),
      matchesGoldenFile('goldens/composer_light.png'),
    );
  });

  testWidgets('sötét szerkesztő golden', (tester) async {
    _usePhoneSurface(tester);
    await _openComposer(tester, ThemeMode.dark);
    await expectLater(
      find.byKey(const Key('composer-sheet')),
      matchesGoldenFile('goldens/composer_dark.png'),
    );
  });

  testWidgets('nagy betűméretű szerkesztő golden', (tester) async {
    _usePhoneSurface(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _openComposer(tester, ThemeMode.light);
    await expectLater(
      find.byKey(const Key('composer-sheet')),
      matchesGoldenFile('goldens/composer_text_scale.png'),
    );
  });
}

Future<void> _openComposer(
  WidgetTester tester,
  ThemeMode mode, {
  String? draft,
}) async {
  SharedPreferences.setMockInitialValues({'composer_draft_text': ?draft});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authGateProvider.overrideWithValue(AsyncData(AuthSignedIn(_coach()))),
        postRepositoryProvider.overrideWithValue(const FakePostRepository()),
      ],
      child: _Harness(mode: mode),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Mire gondolsz, Anna?'));
  await tester.pumpAndSettle();
}

void _usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

PressScale _publishButton(WidgetTester tester) {
  return tester.widget<PressScale>(
    find
        .ancestor(
          of: find.text('Közzététel'),
          matching: find.byType(PressScale),
        )
        .first,
  );
}

TextField _field(WidgetTester tester) {
  return tester.widget<TextField>(find.byType(TextField));
}

class _Harness extends ConsumerWidget {
  const _Harness({required this.mode});

  final ThemeMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: mode,
      routerConfig: ref.watch(appRouterProvider),
      locale: const Locale('hu', 'HU'),
      supportedLocales: const [Locale('hu', 'HU')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

AppUser _coach() {
  return AppUser(
    id: 'coach-1',
    name: 'Kovács Anna',
    email: 'anna@example.com',
    role: UserRole.coach,
    birthDate: DateTime(1990, 4, 2),
    photoUrl: null,
    status: UserStatus.active,
    childIds: const [],
    parentIds: const [],
    childRequests: const [],
    createdAt: DateTime(2026, 1, 1),
  );
}
