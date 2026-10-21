import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/post.dart';

/// `posts` dokumentumok és a domain modell közötti átalakítás.
class PostMapper {
  const PostMapper._();

  static Post postFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw FormatException('Missing post document: ${doc.id}');
    }
    return Post(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorPhotoUrl: _photo(data['authorPhotoUrl']),
      text: data['text'] as String? ?? '',
      createdAt: _date(data['createdAt']),
      updatedAt: _date(data['updatedAt']),
      pinned: data['pinned'] as bool? ?? false,
    );
  }

  static PostCheck checkFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw FormatException('Missing check document: ${doc.id}');
    }
    return PostCheck(
      userId: doc.id,
      userName: data['userName'] as String? ?? '',
      createdAt: _date(data['createdAt']),
    );
  }

  static PostComment commentFromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw FormatException('Missing comment document: ${doc.id}');
    }
    return PostComment(
      id: doc.id,
      authorId: data['authorId'] as String? ?? '',
      authorName: data['authorName'] as String? ?? '',
      authorPhotoUrl: _photo(data['authorPhotoUrl']),
      text: data['text'] as String? ?? '',
      createdAt: _date(data['createdAt']),
    );
  }

  static String? _photo(Object? value) {
    if (value is! String) return null;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  static DateTime _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
