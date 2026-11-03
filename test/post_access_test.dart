import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/features/auth/domain/app_user.dart';
import 'package:subli_app/features/auth/domain/user_role.dart';
import 'package:subli_app/features/auth/domain/user_status.dart';
import 'package:subli_app/features/feed/domain/post.dart';
import 'package:subli_app/features/feed/domain/post_access.dart';

void main() {
  final author = _user('coach-1', UserRole.coach);
  final otherCoach = _user('coach-2', UserRole.coach);
  final admin = _user('admin-1', UserRole.admin);
  final athlete = _user('athlete-1', UserRole.athlete);
  final post = _post(authorId: author.id);
  final comment = _comment(authorId: athlete.id);

  test('a szerző és az admin kezelheti a bejegyzést', () {
    expect(canManagePost(author, post), isTrue);
    expect(canManagePost(admin, post), isTrue);
    expect(canManagePost(otherCoach, post), isFalse);
    expect(canManagePost(athlete, post), isFalse);
    final member = _user('member-1', UserRole.member);
    expect(canManagePost(member, _post(authorId: member.id)), isTrue);
    expect(canManagePost(member, post), isFalse);
  });

  test('egyszerű tagságnál mindenki írhat, kitűzni csak az admin tud', () {
    expect(UserRole.member.canWritePosts, isTrue);
    expect(UserRole.athlete.canWritePosts, isTrue);
    expect(UserRole.member.canPinPosts, isFalse);
    expect(UserRole.coach.canPinPosts, isFalse);
    expect(UserRole.admin.canPinPosts, isTrue);
  });

  test('idegen hozzászólást egyszerű tagságnál csak az admin törölhet', () {
    expect(canDeleteComment(athlete, comment), isTrue);
    expect(canDeleteComment(otherCoach, comment), isFalse);
    expect(canDeleteComment(admin, comment), isTrue);
    expect(canDeleteComment(author, _comment(authorId: 'valaki')), isFalse);
    expect(canDeleteComment(athlete, _comment(authorId: 'valaki')), isFalse);
  });
}

AppUser _user(String id, UserRole role) {
  return AppUser(
    id: id,
    name: 'Teszt',
    email: '$id@example.com',
    role: role,
    birthDate: null,
    photoUrl: null,
    status: UserStatus.active,
    childIds: const [],
    parentIds: const [],
    childRequests: const [],
    createdAt: DateTime(2026, 1, 1),
  );
}

Post _post({required String authorId}) {
  return Post(
    id: 'post-1',
    authorId: authorId,
    authorName: 'Edző',
    authorPhotoUrl: null,
    text: 'Edzés',
    createdAt: DateTime(2026, 10, 21),
    updatedAt: DateTime(2026, 10, 21),
    pinned: false,
  );
}

PostComment _comment({required String authorId}) {
  return PostComment(
    id: 'comment-1',
    authorId: authorId,
    authorName: 'Sportoló',
    authorPhotoUrl: null,
    text: 'Ott leszek.',
    createdAt: DateTime(2026, 10, 21),
  );
}
