import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/app/club_config.dart';
import 'package:subli_app/app/constants.dart';
import 'package:subli_app/app/theme.dart';
import 'package:subli_app/features/auth/data/auth_providers.dart';
import 'package:subli_app/features/auth/domain/auth_repository.dart';
import 'package:subli_app/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('a logó és a klubnév megjelenik', (tester) async {
    await _surface(tester, const Size(390, 844));
    await _pump(tester, _FakeAuth());
    expect(find.text('Subli Lovas Közösségi App'), findsOneWidget);
    expect(find.text('Regisztráció'), findsOneWidget);
    expect(find.text('Készítette: Sysco System'), findsOneWidget);
    expect(find.bySemanticsLabel('Subli'), findsOneWidget);
    final image = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == ClubConfig.logoAsset,
      ),
    );
    expect(image.width, greaterThan(100));
  });

  testWidgets('az e-mail mezőből az Enter a jelszóra ugrik, onnan beléptet', (
    tester,
  ) async {
    final auth = _FakeAuth();
    await _pump(tester, auth);

    await tester.enterText(find.byKey(const Key('login-email')), 'a@b.hu');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pump();

    final password = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('login-password')),
        matching: find.byType(EditableText),
      ),
    );
    expect(password.focusNode.hasFocus, isTrue);

    await tester.enterText(find.byKey(const Key('login-password')), 'titok1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(auth.signInCalls, 1);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(auth.signInCalls, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets(
    'a belépés feliratai megjelennek, a link a támogatói oldalt nyitja',
    (tester) async {
      await _surface(tester, const Size(390, 844));
      final calls = <MethodCall>[];
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        calls.add(call);
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );

      await _pump(tester, _FakeAuth());

      expect(find.text(ClubConfig.loginTitle!), findsOneWidget);
      expect(find.text('sublilotapok.hu'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is RichText &&
              widget.text.toPlainText().contains('támogatásával'),
        ),
        findsOneWidget,
      );
      expect(find.text(ClubConfig.loginCredit!), findsOneWidget);

      final title = tester.widget<Text>(find.byKey(const Key('login-title')));
      final theme = Theme.of(tester.element(find.byKey(const Key('login-title'))));
      expect(title.textAlign, TextAlign.center);
      expect(title.style?.fontWeight, FontWeight.bold);
      expect(title.style?.fontSize, theme.textTheme.titleLarge?.fontSize);
      expect(title.style?.color, theme.colorScheme.onSurface);
      expect(title.style?.color, isNot(AppColors.primary));

      final link = tester.widget<Text>(
        find.descendant(
          of: find.byKey(const Key('login-sponsor-link')),
          matching: find.byType(Text),
        ),
      );
      expect(link.style?.color, AppColors.primary);
      expect(link.style?.fontSize, theme.textTheme.bodySmall?.fontSize);

      final credit = tester.widget<Text>(find.byKey(const Key('login-credit')));
      expect(credit.textAlign, TextAlign.center);
      expect(credit.style?.fontSize, theme.textTheme.bodySmall?.fontSize);
      expect(credit.style?.color, isNot(theme.colorScheme.onSurface));

      await tester.tap(find.byKey(const Key('login-sponsor-link')));
      await tester.pump();
      expect(calls, hasLength(1));
      expect(calls.single.method, 'launch');
      expect(calls.single.arguments['url'], 'https://sublilotapok.hu');
      expect(calls.single.arguments['useWebView'], isFalse);
      expect(calls.single.arguments['useSafariVC'], isFalse);
    },
  );

  testWidgets('sötét témában a cím világos, a link piros marad', (
    tester,
  ) async {
    await _surface(tester, const Size(390, 844));
    await _pump(tester, _FakeAuth(), dark: true);
    final title = tester.widget<Text>(find.byKey(const Key('login-title')));
    final theme = Theme.of(tester.element(find.byKey(const Key('login-title'))));
    expect(theme.brightness, Brightness.dark);
    expect(title.style?.color, theme.colorScheme.onSurface);
    expect(
      tester
          .widget<Text>(
            find.descendant(
              of: find.byKey(const Key('login-sponsor-link')),
              matching: find.byType(Text),
            ),
          )
          .style
          ?.color,
      AppColors.primary,
    );
  });

  testWidgets('üres feliratok nem jelennek meg', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Column(
            children: [
              LoginHeading(title: null, sponsorText: null, sponsorUrl: null),
              LoginCredit(text: null),
            ],
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('login-title')), findsNothing);
    expect(find.byKey(const Key('login-sponsor')), findsNothing);
    expect(find.byKey(const Key('login-credit')), findsNothing);
    expect(find.byKey(const Key('login-sponsor-link')), findsNothing);
  });

  testWidgets('iPhone SE-n a belépés görgetés nélkül kifér', (tester) async {
    await _surface(tester, const Size(375, 667));
    await _pump(tester, _FakeAuth());
    expect(tester.takeException(), isNull);
    final position = Scrollable.of(
      tester.element(find.byKey(const Key('login-credit'))),
    ).position;
    expect(position.maxScrollExtent, 0);
  });

  testWidgets('bejelentkezés világos golden', (tester) async {
    await _surface(tester, const Size(390, 844));
    await _pump(tester, _FakeAuth());
    await _paintLogo(tester);
    await expectLater(
      find.byKey(const Key('login-screen')),
      matchesGoldenFile('goldens/login_light.png'),
    );
  });

  testWidgets('bejelentkezés sötét golden', (tester) async {
    await _surface(tester, const Size(390, 844));
    await _pump(tester, _FakeAuth(), dark: true);
    await _paintLogo(tester);
    await expectLater(
      find.byKey(const Key('login-screen')),
      matchesGoldenFile('goldens/login_dark.png'),
    );
  });

  testWidgets('iPhone SE nyitott billentyűzettel sem csordul túl', (
    tester,
  ) async {
    await _surface(tester, const Size(375, 667), keyboard: 300);
    await _pump(tester, _FakeAuth());
    expect(tester.takeException(), isNull);
    await _paintLogo(tester);
    await expectLater(
      find.byKey(const Key('login-screen')),
      matchesGoldenFile('goldens/login_se_keyboard.png'),
    );
  });
}

Future<void> _surface(
  WidgetTester tester,
  Size size, {
  double keyboard = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
}

Future<void> _pump(
  WidgetTester tester,
  AuthRepository auth, {
  bool dark = false,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: MaterialApp(
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: dark ? ThemeMode.dark : ThemeMode.light,
        home: const LoginScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _paintLogo(WidgetTester tester) async {
  final context = tester.element(find.byType(Image).first);
  await tester.runAsync(() async {
    for (final image in tester.widgetList<Image>(find.byType(Image))) {
      await precacheImage(image.image, context);
    }
  });
  await tester.pumpAndSettle();
}

class _FakeAuth implements AuthRepository {
  int signInCalls = 0;
  final _gate = Completer<void>();

  @override
  Future<void> signIn({required String email, required String password}) {
    signInCalls += 1;
    return _gate.future;
  }

  @override
  Stream<String?> watchUserId() => const Stream.empty();

  @override
  Future<void> signOut() async {}

  @override
  Future<({String id, String email})> createAccount({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteCurrentAccount() async {}

  @override
  Future<void> sendPasswordResetEmail(String email) async {}
}
