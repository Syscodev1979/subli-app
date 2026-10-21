import 'package:gastroyal_karate_app/features/feed/domain/post.dart';
import 'package:gastroyal_karate_app/features/feed/domain/post_repository.dart';

/// Üres hírfolyam a widgettesztekhez, Firebase nélkül.
class FakePostRepository implements PostRepository {
  const FakePostRepository({
    this.page = const PostPage(posts: <Post>[], hasMore: false),
  });

  final PostPage page;

  @override
  Future<PostPage> fetchPosts({
    Object? startAfter,
    int limit = PostLimits.pageSize,
  }) async {
    return page;
  }

  @override
  Stream<Post?> watchPost(String postId) => Stream<Post?>.value(null);

  @override
  Future<String> createPost({
    required String authorId,
    required String authorName,
    required String? authorPhotoUrl,
    required String text,
    required bool pinned,
  }) async {
    return 'new-post';
  }

  @override
  Future<void> updatePost({
    required String postId,
    required String text,
    required bool pinned,
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
