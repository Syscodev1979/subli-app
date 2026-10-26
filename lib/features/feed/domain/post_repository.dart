import 'post.dart';
import 'post_category.dart';
import 'reaction.dart';

/// A hírfolyam Firestore-műveletei.
abstract class PostRepository {
  Future<PostPage> fetchPosts({
    Object? startAfter,
    int limit = PostLimits.pageSize,
    PostCategory? category,
    String? keyword,
  });

  /// A legújabb bejegyzés azonosítója, kategórián belül is.
  Stream<String?> watchNewestPostId({PostCategory? category});

  /// A kategória nélküli bejegyzések `news` kategóriát és keresőszavakat kapnak.
  Future<int> backfillLegacyPosts();

  Stream<Post?> watchPost(String postId);

  String reservePostId();

  Future<String> createPost({
    required String authorId,
    required String authorName,
    required String? authorPhotoUrl,
    required String text,
    required bool pinned,
    required PostCategory category,
    List<PostMedia> media = const [],
    String? postId,
    DateTime? eventStartsAt,
    DateTime? eventEndsAt,
  });

  Future<void> updatePost({
    required String postId,
    required String text,
    required bool pinned,
    required PostCategory category,
    required List<PostMedia> media,
    DateTime? eventStartsAt,
    DateTime? eventEndsAt,
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

  Stream<ReactionType?> watchMyReaction({
    required String postId,
    required String userId,
  });

  Future<void> setReaction({
    required String postId,
    required String userId,
    required String userName,
    required ReactionType type,
  });

  Future<void> removeReaction({required String postId, required String userId});

  Future<int> countReactions(String postId);

  Future<List<PostReaction>> fetchReactions(String postId);

  /// A kártyán látható reakcióikonok, a legutóbbi reakciókból.
  Future<List<ReactionType>> fetchReactionTypes(String postId);

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
