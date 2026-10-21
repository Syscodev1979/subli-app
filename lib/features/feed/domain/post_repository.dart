import 'post.dart';

/// A hírfolyam Firestore-műveletei.
abstract class PostRepository {
  Future<PostPage> fetchPosts({
    Object? startAfter,
    int limit = PostLimits.pageSize,
  });

  Stream<Post?> watchPost(String postId);

  Future<String> createPost({
    required String authorId,
    required String authorName,
    required String? authorPhotoUrl,
    required String text,
    required bool pinned,
  });

  Future<void> updatePost({
    required String postId,
    required String text,
    required bool pinned,
  });

  Future<void> deletePost(String postId);

  Future<int> countChecks(String postId);

  Future<int> countComments(String postId);

  Stream<bool> watchMyCheck({required String postId, required String userId});

  Future<void> addCheck({
    required String postId,
    required String userId,
    required String userName,
  });

  Future<void> removeCheck({required String postId, required String userId});

  Future<List<PostCheck>> fetchChecks(String postId);

  /// A legutóbbi hozzászólások, időrendben.
  Future<List<PostComment>> fetchRecentComments(String postId, {int limit = 2});

  Stream<List<PostComment>> watchComments(String postId);

  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String? authorPhotoUrl,
    required String text,
  });

  Future<void> deleteComment({
    required String postId,
    required String commentId,
  });
}
