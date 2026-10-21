import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastroyal_karate_app/app/constants.dart';
import 'package:gastroyal_karate_app/app/theme.dart';
import 'package:gastroyal_karate_app/features/feed/domain/post.dart';
import 'package:gastroyal_karate_app/features/feed/presentation/post_card.dart';

void main() {
  testWidgets('a kitűzött bejegyzés halvány bordó, a pipa kitöltött', (
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
            checkCount: '3',
            commentCount: '1',
            checkedByMe: true,
            canManage: false,
            checkBusy: false,
            onToggleCheck: () {},
            onShowChecks: () {},
            onOpen: () {},
          ),
        ),
      ),
    );

    expect(
      tester.widget<Card>(find.byType(Card)).color,
      AppColors.burgundyLight,
    );
    expect(find.byIcon(Icons.push_pin), findsOneWidget);
    expect(find.text('KA'), findsOneWidget);
    expect(find.text('tegnap 18:30'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}
