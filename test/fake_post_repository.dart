import 'package:gastroyal_karate_app/features/feed/domain/post.dart';
import 'package:gastroyal_karate_app/features/feed/domain/post_category.dart';
import 'package:gastroyal_karate_app/features/feed/domain/post_repository.dart';
import 'package:gastroyal_karate_app/features/feed/domain/reaction.dart';

/// Üres hírfolyam a widgettesztekhez, Firebase nélkül.
class FakePostRepository implements PostRepository {
  const FakePostRepository({
    this.page = const PostPage(posts: <Post>[], hasMore: false),
    this.onFetch,
  });

  final PostPage page;
  final void Function(PostCategory? category, String? keyword)? onFetch;

  @override
  Future<PostPage> fetchPosts({
    Object? startAfter,
    int limit = PostLimits.pageSize,
    PostCategory? category,
    String? keyword,
  }) async {
    onFetch?.call(category, keyword);
    return page;
  }

  @override
  Stream<String?> watchNewestPostId({PostCategory? category}) {
    return Stream<String?>.value(null);
  }

  @override
  Future<int> backfillLegacyPosts() async => 0;

  @override
  Stream<Post?> watchPost(String postId) => Stream<Post?>.value(null);

  @override
  String reservePostId() => 'new-post';

  @override
  Future<String> createPost({
    required String authorId,
    required String authorName,
    required String? authorPhotoUrl,
    required String text,
    required bool pinned,
    required PostCategory category,
    List<PostMedia> media = const [],
    String? postId,
  }) async {
    return postId ?? 'new-post';
  }

  @override
  Future<void> updatePost({
    required String postId,
    required String text,
    required bool pinned,
    required PostCategory category,
    required List<PostMedia> media,
  }) async {}

  @override
  Future<void> deletePost(String postId) async {}

  @override
  Future<int> countChecks(String postId) async => 0;

  @override
  Future<int> countComments(String postId) async => 0;

  @override
  Stream<bool> watchMyCheck({required String postId, required String userId}) {
    return Stream<bool>.value(false);
  }

  @override
  Future<void> addCheck({
    required String postId,
    required String userId,
    required String userName,
  }) async {}

  @override
  Future<void> removeCheck({
    required String postId,
    required String userId,
  }) async {}

  @override
  Future<List<PostCheck>> fetchChecks(String postId) async => const [];

  @override
  Stream<ReactionType?> watchMyReaction({
    required String postId,
    required String userId,
  }) {
    return Stream<ReactionType?>.value(null);
  }

  @override
  Future<void> setReaction({
    required String postId,
    required String userId,
    required String userName,
    required ReactionType type,
  }) async {}

  @override
  Future<void> removeReaction({
    required String postId,
    required String userId,
  }) async {}

  @override
  Future<int> countReactions(String postId) async => 0;

  @override
  Future<List<PostReaction>> fetchReactions(String postId) async => const [];

  @override
  Future<List<ReactionType>> fetchReactionTypes(String postId) async =>
      const [];

  @override
  Future<List<PostComment>> fetchRecentComments(
    String postId, {
    int limit = 2,
  }) async => const [];

  @override
  Stream<List<PostComment>> watchComments(String postId) {
    return Stream<List<PostComment>>.value(const []);
  }

  @override
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String? authorPhotoUrl,
    required String text,
  }) async {}

  @override
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) async {}
}
