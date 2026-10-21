import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../auth/domain/auth_session.dart';
import '../data/feed_providers.dart';
import '../domain/post.dart';

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
    if (session is! AuthSignedIn) {
      return const FeedView(posts: [], hasMore: false);
    }
    return _firstPage();
  }

  Future<void> refresh() async {
    ref.invalidate(postCheckCountProvider);
    ref.invalidate(postReactionCountProvider);
    ref.invalidate(reactionTypesProvider);
    ref.invalidate(postCommentCountProvider);
    state = AsyncData(await _firstPage());
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final page = await ref
          .read(postRepositoryProvider)
          .fetchPosts(startAfter: current.cursor, limit: PostLimits.pageSize);
      state = AsyncData(
        FeedView(
          posts: [...current.posts, ...page.posts],
          hasMore: page.hasMore,
          cursor: page.posts.isEmpty ? current.cursor : page.cursor,
        ),
      );
    } catch (error) {
      state = AsyncData(current.copyWith(loadingMore: false));
      rethrow;
    }
  }

  Future<FeedView> _firstPage() async {
    final page = await ref
        .read(postRepositoryProvider)
        .fetchPosts(limit: PostLimits.pageSize);
    return FeedView(
      posts: page.posts,
      hasMore: page.hasMore,
      cursor: page.cursor,
    );
  }
}

final feedControllerProvider = AsyncNotifierProvider<FeedController, FeedView>(
  FeedController.new,
);
