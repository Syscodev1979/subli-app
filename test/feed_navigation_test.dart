import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/features/auth/data/auth_providers.dart';
import 'package:subli_app/features/auth/domain/app_user.dart';
import 'package:subli_app/features/auth/domain/auth_session.dart';
import 'package:subli_app/features/auth/domain/user_role.dart';
import 'package:subli_app/features/auth/domain/user_status.dart';
import 'package:subli_app/features/chat/data/chat_providers.dart';
import 'package:subli_app/features/feed/data/feed_providers.dart';
import 'package:subli_app/features/feed/domain/post.dart';
import 'package:subli_app/features/feed/domain/post_category.dart';
import 'package:subli_app/features/feed/presentation/category_style.dart';
import 'package:subli_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_chat_repository.dart';
import 'fake_post_repository.dart';

void main() {
  testWidgets('a lista alján jelzés van, ha minden bejegyzés betöltődött', (
    tester,
  ) async {
    await _pump(tester, PostPage(posts: [_post], hasMore: false));

    expect(find.text('Minden bejegyzést láttál 🐴'), findsOneWidget);
    expect(find.text('Nézz vissza később a friss hírekért!'), findsOneWidget);
    expect(find.text('Hír'), findsWidgets);
    expect(find.text('Keresés a Hírfolyamban…'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('club-app-bar')),
        matching: find.byIcon(Icons.search),
      ),
      findsNothing,
    );
  });

  testWidgets('a kategória és a keresés a lekérdezésbe kerül', (tester) async {
    PostCategory? category;
    String? keyword;
    List<String>? audience;
    await _pump(
      tester,
      PostPage(posts: [_post], hasMore: false),
      onFetch: (nextCategory, nextKeyword, nextAudience) {
        category = nextCategory;
        keyword = nextKeyword;
        audience = nextAudience;
      },
    );

    await tester.tap(find.widgetWithText(CategoryChip, 'Edzés'));
    await tester.pumpAndSettle();
    expect(category, PostCategory.training);

    await tester.tap(find.byKey(const Key('feed-search')));
    await tester.pumpAndSettle();
    expect(find.text('Mégse'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('feed-search')),
      'edzés holnap',
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(keyword, isNull);
    expect(audience, ['all', 'athletes']);
    expect(find.text('Nincs találat erre: edzés holnap'), findsNothing);
  });
}

final _post = Post(
  id: 'post-1',
  authorId: 'coach-1',
  authorName: 'Kovács Anna',
  authorPhotoUrl: null,
  text: 'Holnap közös edzés.',
  createdAt: DateTime(2026, 10, 21, 18, 30),
  updatedAt: DateTime(2026, 10, 21, 18, 30),
  pinned: false,
  category: PostCategory.training,
  searchKeywords: ['holnap', 'kozos', 'edzes'],
);

Future<void> _pump(
  WidgetTester tester,
  PostPage page, {
  void Function(
    PostCategory? category,
    String? keyword,
    List<String>? audience,
  )?
  onFetch,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authGateProvider.overrideWithValue(AsyncData(AuthSignedIn(_athlete()))),
        postRepositoryProvider.overrideWithValue(
          FakePostRepository(page: page, onFetch: onFetch),
        ),
        chatRepositoryProvider.overrideWithValue(const FakeChatRepository()),
      ],
      child: const SubliApp(),
    ),
  );
  await tester.pumpAndSettle();
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
