import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import 'post.dart';

/// Saját bejegyzést a szerző, bármelyiket az admin kezelheti.
bool canManagePost(AppUser user, Post post) {
  return user.role == UserRole.admin || user.id == post.authorId;
}

/// Saját hozzászólást a szerző, bármelyiket admin és edző törölheti.
bool canDeleteComment(AppUser user, PostComment comment) {
  return user.id == comment.authorId || user.role.canReviewMembers;
}
