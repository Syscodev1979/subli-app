import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/feed_providers.dart';
import '../domain/post_category.dart';

/// A hírfolyam kategóriaszűrője. A munkamenet végéig megmarad.
final feedCategoryProvider =
    NotifierProvider<FeedCategoryController, PostCategory?>(
      FeedCategoryController.new,
    );

class FeedCategoryController extends Notifier<PostCategory?> {
  @override
  PostCategory? build() => null;

  void select(PostCategory? category) => state = category;
}

/// A keresőmező késleltetett szövege.
final feedSearchProvider = NotifierProvider<FeedSearchController, String>(
  FeedSearchController.new,
);

class FeedSearchController extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;

  void clear() => state = '';
}

final newestPostIdProvider = StreamProvider<String?>((ref) {
  final search = ref.watch(feedSearchProvider);
  if (search.trim().isNotEmpty) return Stream<String?>.value(null);
  final category = ref.watch(feedCategoryProvider);
  return ref
      .watch(postRepositoryProvider)
      .watchNewestPostId(category: category);
});
