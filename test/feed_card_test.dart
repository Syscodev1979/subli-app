import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/app/constants.dart';
import 'package:subli_app/app/theme.dart';
import 'package:subli_app/features/feed/domain/post.dart';
import 'package:subli_app/features/feed/domain/post_category.dart';
import 'package:subli_app/features/feed/domain/reaction.dart';
import 'package:subli_app/features/feed/presentation/post_card.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('hu');
  });

  testWidgets('a kitűzött bejegyzésen a Like zöld, a kártya fehér', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PostCard(
            post: Post(
              id: 'post-1',
              authorId: 'coach-1',
              authorName: 'Kovács Anna',
              authorPhotoUrl: null,
              text: 'Holnap közös edzés.',
              createdAt: DateTime(2026, 10, 21, 18, 30),
              updatedAt: DateTime(2026, 10, 21, 18, 30),
              pinned: true,
            ),
            timeLabel: 'tegnap 18:30',
            reactionCount: 3,
            reactionTypes: const [ReactionType.like],
            commentCount: 1,
            myReaction: ReactionType.like,
            canManage: true,
            recentComments: [
              PostComment(
                id: 'c1',
                authorId: 'a',
                authorName: 'Nagy Béla',
                authorPhotoUrl: null,
                text: 'Ott leszek.',
                createdAt: DateTime(2026, 10, 21, 19),
              ),
            ],
            onToggleLike: () {},
            onPickReaction: (_) {},
            onShowReactions: () {},
            onOpenComments: () {},
          ),
        ),
      ),
    );

    expect(find.text('Kitűzve'), findsOneWidget);
    expect(find.text('KA'), findsOneWidget);
    expect(find.text('tegnap 18:30'), findsOneWidget);
    expect(find.text('Like'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('1 hozzászólás'), findsOneWidget);
    expect(find.textContaining('Ott leszek.'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Like')).style?.color,
      AppColors.accentGreen,
    );

    expect(
      find.byWidgetPredicate(
        (widget) => widget is ColoredBox && widget.color == AppColors.feedCard,
      ),
      findsOneWidget,
    );
  });

  testWidgets('az esemény kártyáján a naptárnap és az időtartam látszik', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PostCard(
            post: Post(
              id: 'event-1',
              authorId: 'coach-1',
              authorName: 'Kovács Anna',
              authorPhotoUrl: null,
              text: 'Edzőtábor a teremben.',
              createdAt: DateTime(2026, 10, 20, 12),
              updatedAt: DateTime(2026, 10, 20, 12),
              pinned: false,
              category: PostCategory.event,
              eventStartsAt: DateTime(2026, 10, 25, 18),
              eventEndsAt: DateTime(2026, 10, 25, 20),
            ),
            timeLabel: 'tegnap 12:00',
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

    expect(find.byKey(const Key('event-when')), findsOneWidget);
    expect(find.text('Vasárnap'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);
    expect(find.textContaining('18:00'), findsOneWidget);
    expect(find.textContaining('20:00'), findsOneWidget);
    expect(find.textContaining('@'), findsNothing);
  });
}
