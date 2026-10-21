import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/post.dart';
import '../domain/post_repository.dart';
import 'firestore_post_repository.dart';

final postRepositoryProvider = Provider<PostRepository>((ref) {
  return FirestorePostRepository(FirebaseFirestore.instance);
});

final postProvider = StreamProvider.family<Post?, String>((ref, postId) {
  return ref.watch(postRepositoryProvider).watchPost(postId);
});

final postCommentsProvider = StreamProvider.family<List<PostComment>, String>((
  ref,
  postId,
) {
  return ref.watch(postRepositoryProvider).watchComments(postId);
});

/// A számlálók count() aggregációk, nem tárolt mezők.
final postCheckCountProvider = FutureProvider.family<int, String>((
  ref,
  postId,
) {
  return ref.watch(postRepositoryProvider).countChecks(postId);
});

final postCommentCountProvider = FutureProvider.family<int, String>((
  ref,
  postId,
) {
  return ref.watch(postRepositoryProvider).countComments(postId);
});

final recentCommentsProvider = FutureProvider.family<List<PostComment>, String>(
  (ref, postId) {
    return ref.watch(postRepositoryProvider).fetchRecentComments(postId);
  },
);

final myCheckProvider = StreamProvider.family<bool, String>((ref, postId) {
  final session = ref.watch(authGateProvider).asData?.value;
  if (session is! AuthSignedIn) return Stream<bool>.value(false);
  return ref
      .watch(postRepositoryProvider)
      .watchMyCheck(postId: postId, userId: session.user.id);
});
