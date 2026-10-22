import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../auth/domain/auth_session.dart';
import '../data/feed_providers.dart';
import '../domain/post.dart';
import '../domain/post_category.dart';
import '../domain/search_keywords.dart';
import 'feed_query.dart';

/// A hírfolyam egy betöltött állapota, lapozással.
class FeedView {
  const FeedView({
    required this.posts,
    required this.hasMore,
    this.cursor,
    this.loadingMore = false,
  });

  final List<Post> posts;
  final bool hasMore;
  final Object? cursor;
  final bool loadingMore;

  FeedView copyWith({bool? loadingMore}) {
    return FeedView(
      posts: posts,
      hasMore: hasMore,
      cursor: cursor,
      loadingMore: loadingMore ?? this.loadingMore,
    );
  }
}

class FeedController extends AsyncNotifier<FeedView> {
  @override
  Future<FeedView> build() async {
    final session = ref.watch(authGateProvider).asData?.value;
    final category = ref.watch(feedCategoryProvider);
    final search = ref.watch(feedSearchProvider);
    if (session is! AuthSignedIn) {
      return const FeedView(posts: [], hasMore: false);
    }
    return _load(category: category, search: search);
  }

  Future<void> refresh() async {
    ref.invalidate(postCheckCountProvider);
    ref.invalidate(postReactionCountProvider);
    ref.invalidate(reactionTypesProvider);
    ref.invalidate(postCommentCountProvider);
    state = AsyncData(
      await _load(
        category: ref.read(feedCategoryProvider),
        search: ref.read(feedSearchProvider),
      ),
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await _load(
        category: ref.read(feedCategoryProvider),
        search: ref.read(feedSearchProvider),
        previous: current.posts,
        cursor: current.cursor,
      );
      state = AsyncData(page);
    } catch (error) {
      state = AsyncData(current.copyWith(loadingMore: false));
      rethrow;
    }
  }

  Future<FeedView> _load({
    required PostCategory? category,
    required String search,
    List<Post> previous = const [],
    Object? cursor,
  }) async {
    final terms = searchTerms(search);
    if (search.trim().isNotEmpty && terms.isEmpty) {
      return const FeedView(posts: [], hasMore: false);
    }
    var posts = previous;
    var start = cursor;
    var hasMore = true;
    Object? nextCursor = cursor;
    for (var hop = 0; hop < 4 && hasMore; hop++) {
      final page = await ref
          .read(postRepositoryProvider)
          .fetchPosts(
            startAfter: start,
            limit: PostLimits.pageSize,
            category: category,
            keyword: terms.isEmpty ? null : terms.first,
          );
      final matched = [
        for (final post in page.posts)
          if (matchesExtraTerms(post.searchText, terms)) post,
      ];
      posts = [...posts, ...matched];
      hasMore = page.hasMore;
      nextCursor = page.cursor;
      if (matched.isNotEmpty || !hasMore) break;
      start = page.cursor;
    }
    return FeedView(posts: posts, hasMore: hasMore, cursor: nextCursor);
  }
}

final feedControllerProvider = AsyncNotifierProvider<FeedController, FeedView>(
  FeedController.new,
);
