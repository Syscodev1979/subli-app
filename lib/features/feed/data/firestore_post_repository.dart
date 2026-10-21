import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../domain/post.dart';
import '../domain/post_repository.dart';
import '../domain/reaction.dart';
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
  }) async {
    var query = _posts
        .orderBy('pinned', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit);
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
  String reservePostId() => _posts.doc().id;

  @override
  Future<String> createPost({
    required String authorId,
    required String authorName,
    required String? authorPhotoUrl,
    required String text,
    required bool pinned,
    List<PostMedia> media = const [],
    String? postId,
  }) async {
    final ref = postId == null ? _posts.doc() : _posts.doc(postId);
    final now = Timestamp.fromDate(DateTime.now());
    await ref.set({
      'authorId': authorId,
      'authorName': authorName,
      'authorPhotoUrl': authorPhotoUrl,
      'text': text,
      'createdAt': now,
      'updatedAt': now,
      'pinned': pinned,
      'media': [for (final item in media) item.toMap()],
    });
    return ref.id;
  }

  @override
  Future<void> updatePost({
    required String postId,
    required String text,
    required bool pinned,
    required List<PostMedia> media,
  }) {
    return _posts.doc(postId).update({
      'text': text,
      'pinned': pinned,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
      'media': [for (final item in media) item.toMap()],
    });
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
