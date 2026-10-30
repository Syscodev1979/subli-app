import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastroyal_karate_app/app/club_config.dart';
import 'package:gastroyal_karate_app/app/theme.dart';
import 'package:gastroyal_karate_app/features/auth/data/auth_providers.dart';
import 'package:gastroyal_karate_app/features/auth/domain/auth_repository.dart';
import 'package:gastroyal_karate_app/features/auth/presentation/login_screen.dart';

void main() {
  testWidgets('a logó és a köszöntés megjelenik', (tester) async {
    await _surface(tester, const Size(390, 844));
    await _pump(tester, _FakeAuth());
    expect(find.text('Gastroyal Karate SE'), findsOneWidget);
    expect(find.text('Üdv a klub zárt közösségében!'), findsOneWidget);
    expect(find.bySemanticsLabel('Klublogó'), findsOneWidget);
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
  Stream<({String id, String? email, bool emailVerified})?> watchIdentity() =>
      const Stream.empty();

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

  @override
  Future<void> sendEmailVerification() async {}

  @override
  Future<void> reloadCurrentUser() async {}
}
