/// Egy hírfolyam-bejegyzés. A szerző neve és fotója denormalizált.
class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
    required this.updatedAt,
    required this.pinned,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pinned;
}

/// Egy pipa. A dokumentum azonosítója a pipázó felhasználóé.
class PostCheck {
  const PostCheck({
    required this.userId,
    required this.userName,
    required this.createdAt,
  });

  final String userId;
  final String userName;
  final DateTime createdAt;
}

/// Hozzászólás egy bejegyzéshez.
class PostComment {
  const PostComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhotoUrl,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;
}

/// Egy lap a hírfolyamból. A [cursor] a következő lap kiinduló pontja.
class PostPage {
  const PostPage({required this.posts, required this.hasMore, this.cursor});

  final List<Post> posts;
  final bool hasMore;
  final Object? cursor;
}

/// A hírfolyam méretkorlátai, a Firestore-szabályokkal egyezően.
abstract final class PostLimits {
  static const int pageSize = 20;
  static const int postText = 5000;
  static const int commentText = 1000;
  static const int authorName = 120;
}
