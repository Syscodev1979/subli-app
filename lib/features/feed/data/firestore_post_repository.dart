import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/event_time.dart';
import '../domain/post.dart';
import '../domain/post_category.dart';
import '../domain/post_repository.dart';
import '../domain/reaction.dart';
import '../domain/search_keywords.dart';
import 'post_mapper.dart';
import 'post_media_storage.dart';

class FirestorePostRepository implements PostRepository {
  FirestorePostRepository(this._firestore, {FirebaseStorage? storage})
    : _media = PostMediaStorage(storage ?? FirebaseStorage.instance);

  final FirebaseFirestore _firestore;
  final PostMediaStorage _media;

  CollectionReference<Map<String, dynamic>> get _posts =>
      _firestore.collection('posts');

  @override
  Future<PostPage> fetchPosts({
    Object? startAfter,
    int limit = PostLimits.pageSize,
    PostCategory? category,
    String? keyword,
    List<String>? audience,
  }) async {
    Query<Map<String, dynamic>> query = _scoped(_posts, audience);
    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    // A szerep szűrője már tömbfeltétel. A Firestore egy lekérdezésben
    // csak egyet enged, ezért a keresőszót ilyenkor a kliens szűri.
    if (audience == null && keyword != null && keyword.isNotEmpty) {
      query = query
          .where('searchKeywords', arrayContains: keyword)
          .orderBy('createdAt', descending: true);
    } else if (keyword != null && keyword.isNotEmpty) {
      query = query.orderBy('createdAt', descending: true);
    } else {
      query = query
          .orderBy('pinned', descending: true)
          .orderBy('createdAt', descending: true);
    }
    query = query.limit(limit);
    if (startAfter != null) {
      if (startAfter is! DocumentSnapshot<Object?>) {
        throw ArgumentError('Invalid post page cursor.');
      }
      query = query.startAfterDocument(startAfter);
    }
    final snapshot = await query.get();
    return PostPage(
      posts: snapshot.docs.map(PostMapper.postFromDoc).toList(),
      hasMore: snapshot.docs.length == limit,
      cursor: snapshot.docs.isEmpty ? startAfter : snapshot.docs.last,
    );
  }

  @override
  Stream<Post?> watchPost(String postId) {
    return _posts.doc(postId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PostMapper.postFromDoc(doc);
    });
  }

  @override
  Stream<String?> watchNewestPostId({
    PostCategory? category,
    List<String>? audience,
  }) {
    Query<Map<String, dynamic>> query = _scoped(_posts, audience);
    if (category != null) {
      query = query.where('category', isEqualTo: category.name);
    }
    return query
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.isEmpty ? null : snapshot.docs.first.id,
        );
  }

  @override
  Future<int> backfillLegacyPosts() async {
    var updated = 0;
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    while (true) {
      var query = _posts.orderBy(FieldPath.documentId).limit(200);
      if (cursor != null) query = query.startAfterDocument(cursor);
      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;
      var batch = _firestore.batch();
      var writes = 0;
      for (final document in snapshot.docs) {
        final data = document.data();
        final hasCategory = data['category'] is String;
        final hasAudience =
            data['audience'] is List && (data['audience'] as List).isNotEmpty;
        if (hasCategory && hasAudience) continue;
        final text = data['text'] is String ? data['text'] as String : '';
        batch.update(document.reference, {
          if (!hasCategory) 'category': PostCategory.news.name,
          if (!hasCategory)
            'searchKeywords': postSearchKeywords(
              text: text,
              maxWords: PostLimits.maxSearchKeywords,
            ),
          if (!hasAudience) 'audience': const ['all'],
        });
        writes++;
        updated++;
        if (writes == 400) {
          await batch.commit();
          batch = _firestore.batch();
          writes = 0;
        }
      }
      if (writes > 0) await batch.commit();
      cursor = snapshot.docs.last;
      if (snapshot.docs.length < 200) break;
    }
    return updated;
  }

  @override
  String reservePostId() => _posts.doc().id;

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
    DateTime? eventStartsAt,
    DateTime? eventEndsAt,
    List<String> audience = const ['all'],
  }) async {
    final ref = postId == null ? _posts.doc() : _posts.doc(postId);
    final now = Timestamp.fromDate(DateTime.now());
    final schedule = _eventFields(
      category: category,
      eventStartsAt: eventStartsAt,
      eventEndsAt: eventEndsAt,
      deleting: false,
    );
    await ref.set({
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'createdAt': now,
      'updatedAt': now,
      'pinned': pinned,
      'category': category.name,
      'searchKeywords': _keywords(
        text: text,
        media: media,
        category: category,
        eventStartsAt: eventStartsAt,
      ),
      'media': [for (final item in media) item.toMap()],
      'audience': audience,
      ...schedule,
    });
    return ref.id;
  }

  @override
  Future<void> updatePost({
    required String postId,
    required String text,
    required bool pinned,
    required PostCategory category,
    required List<PostMedia> media,
    DateTime? eventStartsAt,
    DateTime? eventEndsAt,
    List<String> audience = const ['all'],
  }) {
    return _posts.doc(postId).update({
      'text': text,
      'pinned': pinned,
      'category': category.name,
      'searchKeywords': _keywords(
        text: text,
        media: media,
        category: category,
        eventStartsAt: eventStartsAt,
      ),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'media': [for (final item in media) item.toMap()],
      'audience': audience,
      ..._eventFields(
        category: category,
        eventStartsAt: eventStartsAt,
        eventEndsAt: eventEndsAt,
        deleting: true,
      ),
    });
  }

  Query<Map<String, dynamic>> _scoped(
    Query<Map<String, dynamic>> query,
    List<String>? audience,
  ) {
    final values = audience;
    if (values == null || values.isEmpty) return query;
    return query.where('audience', arrayContainsAny: values);
  }

  List<String> _keywords({
    required String text,
    required List<PostMedia> media,
    required PostCategory category,
    required DateTime? eventStartsAt,
  }) {
    return postSearchKeywords(
      text: text,
      media: media,
      extra: category == PostCategory.event && eventStartsAt != null
          ? eventSearchText(eventStartsAt)
          : '',
      maxWords: PostLimits.maxSearchKeywords,
    );
  }

  /// Létrehozáskor csak a meglévő időpontok kerülnek a dokumentumba.
  /// Módosításkor a hiányzó mezők törlődnek, ha a bejegyzés már nem esemény.
  Map<String, Object> _eventFields({
    required PostCategory category,
    required DateTime? eventStartsAt,
    required DateTime? eventEndsAt,
    required bool deleting,
  }) {
    final start = eventStartsAt;
    final end = eventEndsAt;
    if (category != PostCategory.event || start == null) {
      if (!deleting) return const {};
      return {
        'eventStartsAt': FieldValue.delete(),
        'eventEndsAt': FieldValue.delete(),
      };
    }
    if (!deleting) {
      return {
        'eventStartsAt': Timestamp.fromDate(start),
        if (end != null) 'eventEndsAt': Timestamp.fromDate(end),
      };
    }
    return {
      'eventStartsAt': Timestamp.fromDate(start),
      'eventEndsAt': end == null
          ? FieldValue.delete()
          : Timestamp.fromDate(end),
    };
  }

  @override
  Future<void> deletePost(String postId) async {
    final post = _posts.doc(postId);
    await _media.deletePost(postId);
    await _deleteAll(post.collection('checks'));
    await _deleteAll(post.collection('reactions'));
    await _deleteAll(post.collection('comments'));
    await post.delete();
  }

  @override
  Future<int> countChecks(String postId) {
    return _count(_posts.doc(postId).collection('checks'));
  }

  @override
  Future<int> countComments(String postId) {
    return _count(_posts.doc(postId).collection('comments'));
  }

  @override
  Stream<bool> watchMyCheck({required String postId, required String userId}) {
    return _posts
        .doc(postId)
        .collection('checks')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  @override
  Future<void> addCheck({
    required String postId,
    required String userId,
    required String userName,
  }) {
    return _posts.doc(postId).collection('checks').doc(userId).set({
      'userName': userName,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> removeCheck({required String postId, required String userId}) {
    return _posts.doc(postId).collection('checks').doc(userId).delete();
  }

  @override
  Future<List<PostCheck>> fetchChecks(String postId) async {
    final snapshot = await _posts
        .doc(postId)
        .collection('checks')
        .orderBy('createdAt')
        .get();
    return snapshot.docs.map(PostMapper.checkFromDoc).toList();
  }

  @override
  Stream<ReactionType?> watchMyReaction({
    required String postId,
    required String userId,
  }) {
    return _posts
        .doc(postId)
        .collection('reactions')
        .doc(userId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) return null;
          return ReactionType.fromName(doc.data()?['type']);
        });
  }

  @override
  Future<void> setReaction({
    required String postId,
    required String userId,
    required String userName,
    required ReactionType type,
  }) {
    return _posts.doc(postId).collection('reactions').doc(userId).set({
      'userName': userName,
      'type': type.name,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> removeReaction({
    required String postId,
    required String userId,
  }) {
    return _posts.doc(postId).collection('reactions').doc(userId).delete();
  }

  @override
  Future<int> countReactions(String postId) {
    return _count(_posts.doc(postId).collection('reactions'));
  }

  @override
  Future<List<PostReaction>> fetchReactions(String postId) async {
    final snapshot = await _posts
        .doc(postId)
        .collection('reactions')
        .orderBy('createdAt')
        .get();
    return snapshot.docs.map(PostMapper.reactionFromDoc).toList();
  }

  @override
  Future<List<ReactionType>> fetchReactionTypes(String postId) async {
    final snapshot = await _posts
        .doc(postId)
        .collection('reactions')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .get();
    final found = <ReactionType>{};
    for (final doc in snapshot.docs) {
      final type = ReactionType.fromName(doc.data()['type']);
      if (type != null) found.add(type);
    }
    return [
      for (final type in ReactionType.values)
        if (found.contains(type)) type,
    ];
  }

  @override
  Future<List<PostComment>> fetchRecentComments(
    String postId, {
    int limit = 2,
  }) async {
    final snapshot = await _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map(PostMapper.commentFromDoc)
        .toList()
        .reversed
        .toList();
  }

  @override
  Stream<List<PostComment>> watchComments(String postId) {
    return _posts
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(PostMapper.commentFromDoc).toList(),
        );
  }

  @override
  Future<void> addComment({
    required String postId,
    required String authorId,
    required String authorName,
    required String? authorPhotoUrl,
    required String text,
  }) {
    return _posts.doc(postId).collection('comments').doc().set({
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'createdAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> deleteComment({
    required String postId,
    required String commentId,
  }) {
    return _posts.doc(postId).collection('comments').doc(commentId).delete();
  }

  Future<int> _count(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    final snapshot = await collection.count().get();
    return snapshot.count ?? 0;
  }

  Future<void> _deleteAll(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    while (true) {
      final snapshot = await collection.limit(500).get();
      if (snapshot.docs.isEmpty) return;
      final batch = _firestore.batch();
      for (final document in snapshot.docs) {
        batch.delete(document.reference);
      }
      await batch.commit();
      if (snapshot.docs.length < 500) return;
    }
  }
}
