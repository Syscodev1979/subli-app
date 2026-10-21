import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastroyal_karate_app/app/constants.dart';
import 'package:gastroyal_karate_app/app/theme.dart';
import 'package:gastroyal_karate_app/features/feed/domain/post.dart';
import 'package:gastroyal_karate_app/features/feed/domain/reaction.dart';
import 'package:gastroyal_karate_app/features/feed/presentation/post_card.dart';

void main() {
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
}
