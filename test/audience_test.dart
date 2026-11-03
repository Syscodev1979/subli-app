import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/app/club_config.dart';
import 'package:subli_app/app/theme.dart';
import 'package:subli_app/features/feed/domain/post.dart';
import 'package:subli_app/features/feed/domain/post_audience.dart';
import 'package:subli_app/features/feed/presentation/audience_sheet.dart';
import 'package:subli_app/features/feed/presentation/post_card.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('hu');
  });

  setUp(() {
    ClubConfig.debugAdultsOnlyOverride = false;
    ClubConfig.debugSelectableAudiencesOverride = const [
      'all',
      'staff',
      'parents',
      'athletes',
    ];
  });
  tearDown(() {
    ClubConfig.debugAdultsOnlyOverride = null;
    ClubConfig.debugSelectableAudiencesOverride = null;
  });

  test('a Subli csak a minden tagot kínálja, választó nélkül', () {
    ClubConfig.debugSelectableAudiencesOverride = null;
    expect(ClubConfig.selectableAudienceKeys, ['all']);
    expect(ClubConfig.showsAudiencePicker, isFalse);
    expect(
      ClubConfig.visibleAudiences.map((option) => option.key),
      ['all'],
    );
  });

  test('a minden tag kizárólagos, a többiből több is választható', () {
    final parents = PostAudience.toggle(
      PostAudience.everyone,
      PostAudience.parents,
      selected: true,
    );
    expect(parents, [PostAudience.parents]);

    final both = PostAudience.toggle(
      parents,
      PostAudience.athletes,
      selected: true,
    );
    expect(both, [PostAudience.parents, PostAudience.athletes]);

    final everyone = PostAudience.toggle(
      both,
      PostAudience.all,
      selected: true,
    );
    expect(everyone, PostAudience.everyone);

    final kept = PostAudience.toggle(
      PostAudience.everyone,
      PostAudience.all,
      selected: false,
    );
    expect(kept, PostAudience.everyone);

    final stillParents = PostAudience.toggle(
      [PostAudience.parents],
      PostAudience.parents,
      selected: false,
    );
    expect(stillParents, [PostAudience.parents]);
  });

  testWidgets(
    'a célközönség lapján a minden tag kizáró, több sor is jelölhető',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () =>
                      showAudienceSheet(context, PostAudience.everyone),
                  child: const Text('Nyisd'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Nyisd'));
      await tester.pumpAndSettle();

      expect(find.text('Ki láthatja?'), findsOneWidget);
      expect(find.text('A vezetőség mindig látja.'), findsOneWidget);
      expect(_checked(tester, '🌐 Minden tag'), isTrue);
      expect(_checked(tester, '🥋 Edzők és adminok'), isFalse);

      await tester.tap(find.text('👨‍👩‍👧 Szülők'));
      await tester.pumpAndSettle();
      expect(_checked(tester, '🌐 Minden tag'), isFalse);
      expect(_checked(tester, '👨‍👩‍👧 Szülők'), isTrue);

      await tester.tap(find.text('🏃 Sportolók'));
      await tester.pumpAndSettle();
      expect(_checked(tester, '👨‍👩‍👧 Szülők'), isTrue);
      expect(_checked(tester, '🏃 Sportolók'), isTrue);
      expect(_checked(tester, '🥋 Edzők és adminok'), isFalse);

      await tester.tap(find.text('🌐 Minden tag'));
      await tester.pumpAndSettle();
      expect(_checked(tester, '🌐 Minden tag'), isTrue);
      expect(_checked(tester, '👨‍👩‍👧 Szülők'), isFalse);
      expect(_checked(tester, '🏃 Sportolók'), isFalse);
    },
  );

  testWidgets('18 év feletti klubban a Szülők célközönség rejtve van', (
    tester,
  ) async {
    ClubConfig.debugAdultsOnlyOverride = true;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () =>
                    showAudienceSheet(context, PostAudience.everyone),
                child: const Text('Nyisd'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('Nyisd'));
    await tester.pumpAndSettle();
    expect(find.text('👨‍👩‍👧 Szülők'), findsNothing);
    expect(find.text('🏃 Sportolók'), findsOneWidget);
    expect(find.text('🌐 Minden tag'), findsOneWidget);
  });

  testWidgets('nem mindenkinek szóló kártyán lakat és felirat van', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PostCard(
            post: _post([PostAudience.staff]),
            timeLabel: 'tegnap 18:30',
            reactionCount: 0,
            reactionTypes: const [],
            commentCount: 0,
            myReaction: null,
            canManage: false,
            recentComments: const [],
            onToggleLike: () {},
            onPickReaction: (_) {},
            onShowReactions: () {},
            onOpenComments: () {},
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.lock), findsOneWidget);
    expect(find.text('Edzők és adminok'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PostCard(
            post: _post([PostAudience.parents, PostAudience.athletes]),
            timeLabel: 'tegnap 18:30',
            reactionCount: 0,
            reactionTypes: const [],
            commentCount: 0,
            myReaction: null,
            canManage: false,
            recentComments: const [],
            onToggleLike: () {},
            onPickReaction: (_) {},
            onShowReactions: () {},
            onOpenComments: () {},
          ),
        ),
      ),
    );

    expect(find.text('Szülők, Sportolók'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PostCard(
            post: _post(PostAudience.everyone),
            timeLabel: 'tegnap 18:30',
            reactionCount: 0,
            reactionTypes: const [],
            commentCount: 0,
            myReaction: null,
            canManage: false,
            recentComments: const [],
            onToggleLike: () {},
            onPickReaction: (_) {},
            onShowReactions: () {},
            onOpenComments: () {},
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('audience-lock')), findsNothing);
  });
}

bool _checked(WidgetTester tester, String title) {
  return tester
      .widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, title))
      .value!;
}

Post _post(List<PostAudience> audience) {
  return Post(
    id: 'post-1',
    authorId: 'coach-1',
    authorName: 'Kovács Anna',
    authorPhotoUrl: null,
    text: 'Belső hír.',
    createdAt: DateTime(2026, 10, 21, 18, 30),
    updatedAt: DateTime(2026, 10, 21, 18, 30),
    pinned: false,
    audience: audience,
  );
}
