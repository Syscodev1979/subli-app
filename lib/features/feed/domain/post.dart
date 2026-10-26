import 'event_time.dart';
import 'post_category.dart';

enum PostMediaType { image, video, document }

/// Egy kép, videó vagy dokumentum a bejegyzésen.
///
/// A [durationSec] csak videónál van kitöltve. A [name], [sizeBytes] és
/// [mimeType] csak dokumentumnál.
class PostMedia {
  const PostMedia({
    required this.type,
    required this.url,
    this.thumbUrl,
    this.width,
    this.height,
    this.durationSec,
    this.name,
    this.sizeBytes,
    this.mimeType,
  });

  final PostMediaType type;
  final String url;
  final String? thumbUrl;
  final int? width;
  final int? height;
  final int? durationSec;
  final String? name;
  final int? sizeBytes;
  final String? mimeType;

  Map<String, Object?> toMap() {
    if (type == PostMediaType.document) {
      return {
        'type': type.name,
        'url': url,
        'name': name,
        'sizeBytes': sizeBytes,
        'mimeType': mimeType,
      };
    }
    return {
      'type': type.name,
      'url': url,
      'thumbUrl': thumbUrl,
      'width': width,
      'height': height,
      'durationSec': durationSec,
    };
  }

  static List<PostMedia> listFrom(Object? raw) {
    if (raw is! List) return const [];
    return [for (final item in raw) ?_fromMap(item)];
  }

  static PostMedia? _fromMap(Object? raw) {
    if (raw is! Map) return null;
    final typeName = raw['type'];
    final url = raw['url'];
    if (url is! String || url.isEmpty) return null;
    final type = switch (typeName) {
      'image' => PostMediaType.image,
      'video' => PostMediaType.video,
      'document' => PostMediaType.document,
      _ => null,
    };
    if (type == null) return null;
    return PostMedia(
      type: type,
      url: url,
      thumbUrl: raw['thumbUrl'] is String ? raw['thumbUrl'] as String : null,
      width: raw['width'] is int ? raw['width'] as int : null,
      height: raw['height'] is int ? raw['height'] as int : null,
      durationSec: raw['durationSec'] is int ? raw['durationSec'] as int : null,
      name: raw['name'] is String ? raw['name'] as String : null,
      sizeBytes: raw['sizeBytes'] is int ? raw['sizeBytes'] as int : null,
      mimeType: raw['mimeType'] is String ? raw['mimeType'] as String : null,
    );
  }
}

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
    this.category = PostCategory.news,
    this.searchKeywords = const [],
    this.media = const [],
    this.eventStartsAt,
    this.eventEndsAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String? authorPhotoUrl;
  final String text;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool pinned;
  final PostCategory category;
  final List<String> searchKeywords;
  final List<PostMedia> media;

  /// Eseménynél a kezdés. Más kategóriánál nincs kitöltve.
  final DateTime? eventStartsAt;

  /// Eseménynél a vége, ha megadták.
  final DateTime? eventEndsAt;

  List<PostMedia> get images => [
    for (final item in media)
      if (item.type == PostMediaType.image) item,
  ];

  PostMedia? get video {
    for (final item in media) {
      if (item.type == PostMediaType.video) return item;
    }
    return null;
  }

  List<PostMedia> get documents => [
    for (final item in media)
      if (item.type == PostMediaType.document) item,
  ];

  /// A keresés második szavát a szövegben, a dokumentumnevekben és a dátumban keresi.
  String get searchText {
    final parts = <String>[
      text,
      for (final item in documents)
        if (item.name != null) item.name!,
      if (eventStartsAt != null) eventSearchText(eventStartsAt!),
    ];
    return parts.join(' ');
  }
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
  static const int maxImages = 10;
  static const int maxMedia = 10;
  static const int maxVideos = 1;
  static const int maxVideoSeconds = 180;
  static const int maxImageBytes = 10 * 1024 * 1024;
  static const int maxVideoBytes = 100 * 1024 * 1024;
  static const int maxDocuments = 5;
  static const int maxDocumentBytes = 20 * 1024 * 1024;
  static const int maxSearchKeywords = 200;
  static const int imageLongestSide = 2048;
  static const int imageQuality = 80;
}
