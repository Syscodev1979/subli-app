import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastroyal_karate_app/app/club_config.dart';
import 'package:gastroyal_karate_app/app/theme_controller.dart';
import 'package:gastroyal_karate_app/features/auth/data/auth_providers.dart';
import 'package:gastroyal_karate_app/features/auth/domain/app_user.dart';
import 'package:gastroyal_karate_app/features/auth/domain/auth_session.dart';
import 'package:gastroyal_karate_app/features/auth/domain/user_role.dart';
import 'package:gastroyal_karate_app/features/auth/domain/user_status.dart';
import 'package:gastroyal_karate_app/features/chat/data/chat_providers.dart';
import 'package:gastroyal_karate_app/features/feed/data/feed_providers.dart';
import 'package:gastroyal_karate_app/features/feed/domain/post.dart';
import 'package:gastroyal_karate_app/features/feed/domain/post_category.dart';
import 'package:gastroyal_karate_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_chat_repository.dart';
import 'fake_post_repository.dart';

void main() {
  testWidgets('iPhone SE méreten 1.3-as betűnél is a teljes klubnév látszik', (
    tester,
  ) async {
    _useSurface(tester, const Size(375, 667));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await _pump(tester);

    expect(tester.takeException(), isNull);
    expect(find.text('Gastroyal Karate SE'), findsOneWidget);
    expect(find.text('Gastroyal'), findsNothing);
    final image = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName == ClubConfig.logoAsset,
      ),
    );
    expect(image.height, 36);
    expect((image.image as AssetImage).assetName, ClubConfig.logoAsset);
    expect(image.filterQuality, FilterQuality.high);
  });

  testWidgets('360 px alatt a rövid klubnév jelenik meg', (tester) async {
    _useSurface(tester, const Size(359, 700));
    await _pump(tester);

    expect(find.text('Gastroyal'), findsOneWidget);
    expect(find.text('Gastroyal Karate SE'), findsNothing);
  });

  testWidgets('a keresősáv törölhető és a Mégse bezárja', (tester) async {
    await _pump(tester);

    await tester.tap(find.byKey(const Key('feed-search')));
    await tester.pump();
    expect(find.text('Mégse'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('feed-search')), 'edzés');
    await tester.pump();
    expect(find.byTooltip('Törlés'), findsOneWidget);

    await tester.tap(find.byTooltip('Törlés'));
    await tester.pump();
    expect(find.text('edzés'), findsNothing);
    expect(find.text('Mégse'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('feed-search')), 'edzés');
    await tester.pump();
    await tester.tap(find.text('Mégse'));
    await tester.pumpAndSettle();
    expect(find.text('Mégse'), findsNothing);
    expect(find.text('edzés'), findsNothing);
    expect(find.text('Keresés a Hírfolyamban…'), findsOneWidget);
  });

  testWidgets('a keresősáv a listával gördül, a tetejére ugrás visszahozza', (
    tester,
  ) async {
    _useSurface(tester, const Size(800, 500));
    await _pump(tester, posts: List.generate(6, _post));
    expect(find.text('Edzés 0'), findsWidgets);
    Finder search() =>
        find.byKey(const Key('feed-search'), skipOffstage: false);

    final before = tester.getTopLeft(search()).dy;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -160));
    await tester.pumpAndSettle();
    final scrolled = tester.getTopLeft(search()).dy;
    expect(scrolled, lessThan(before));

    await tester.tap(find.text('Gastroyal Karate SE'));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(search()).dy, greaterThan(scrolled));
  });

  testWidgets('fejléc világos golden', (tester) async {
    _useSurface(tester, const Size(375, 667));
    await _pump(tester);
    await _paintImages(tester);
    await expectLater(
      find.byKey(const Key('club-app-bar')),
      matchesGoldenFile('goldens/header_light.png'),
    );
  });

  testWidgets('fejléc sötét golden', (tester) async {
    _useSurface(tester, const Size(375, 667));
    await _pump(tester, dark: true);
    await _paintImages(tester);
    await expectLater(
      find.byKey(const Key('club-app-bar')),
      matchesGoldenFile('goldens/header_dark.png'),
    );
  });

  testWidgets('hírfolyam teteje világos golden', (tester) async {
    _useSurface(tester, const Size(375, 667));
    await _pump(tester);
    await expectLater(
      find.byKey(const Key('feed-top')),
      matchesGoldenFile('goldens/feed_top_light.png'),
    );
  });

  testWidgets('hírfolyam teteje sötét golden', (tester) async {
    _useSurface(tester, const Size(375, 667));
    await _pump(tester, dark: true);
    await expectLater(
      find.byKey(const Key('feed-top')),
      matchesGoldenFile('goldens/feed_top_dark.png'),
    );
  });
}

void _useSurface(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _pump(
  WidgetTester tester, {
  bool dark = false,
  List<Post>? posts,
}) async {
  SharedPreferences.setMockInitialValues({
    if (dark) ThemeController.storageKey: 'dark',
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authGateProvider.overrideWithValue(AsyncData(AuthSignedIn(_athlete()))),
        postRepositoryProvider.overrideWithValue(
          FakePostRepository(
            page: PostPage(posts: posts ?? const [], hasMore: false),
          ),
        ),
        chatRepositoryProvider.overrideWithValue(const FakeChatRepository()),
      ],
      child: const GastroyalApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _paintImages(WidgetTester tester) async {
  final context = tester.element(find.byType(Image).first);
  final images = tester.widgetList<Image>(find.byType(Image));
  await tester.runAsync(() async {
    for (final image in images) {
      await precacheImage(image.image, context);
    }
  });
  await tester.pumpAndSettle();
}

Post _post(int index) {
  return Post(
    id: 'post-$index',
    authorId: 'coach-1',
    authorName: 'Kovács Anna',
    authorPhotoUrl: null,
    text: 'Edzés $index',
    createdAt: DateTime(2026, 10, 21, 18, index),
    updatedAt: DateTime(2026, 10, 21, 18, index),
    pinned: false,
    category: PostCategory.training,
    searchKeywords: const ['edzes'],
  );
}

AppUser _athlete() {
  return AppUser(
    id: 'athlete-1',
    name: 'Teszt Sportoló',
    email: 'teszt@example.com',
    role: UserRole.athlete,
    photoUrl: null,
    status: UserStatus.active,
    birthDate: DateTime(2000, 1, 1),
    childIds: const [],
    parentIds: const [],
    childRequests: const [],
    createdAt: DateTime(2026, 1, 1),
  );
}
