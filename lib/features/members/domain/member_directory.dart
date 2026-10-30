import '../../auth/domain/app_user.dart';
import '../../auth/domain/user_role.dart';
import '../../auth/domain/user_status.dart';
import 'text_fold.dart';
import 'training_group.dart';

class MemberDirectoryQuery {
  const MemberDirectoryQuery({
    this.search = '',
    this.status,
    this.role,
    this.groupId,
  });

  final String search;
  final UserStatus? status;
  final UserRole? role;
  final String? groupId;
}

class MemberCounts {
  const MemberCounts({
    required this.active,
    required this.pending,
    required this.suspended,
  });

  final int active;
  final int pending;
  final int suspended;
}

MemberCounts memberCounts(List<AppUser> members) {
  return MemberCounts(
    active: members.where((user) => user.status == UserStatus.active).length,
    pending: members.where((user) => user.status == UserStatus.pending).length,
    suspended: members
        .where((user) => user.status == UserStatus.suspended)
        .length,
  );
}

List<AppUser> filterMembers(
  List<AppUser> members,
  MemberDirectoryQuery query,
) {
  return [
    for (final user in members)
      if (_matches(user, query)) user,
  ];
}

bool _matches(AppUser user, MemberDirectoryQuery query) {
  if (query.status != null && user.status != query.status) return false;
  if (query.role != null && user.role != query.role) return false;
  if (query.groupId != null && !user.groupIds.contains(query.groupId)) {
    return false;
  }
  final needle = query.search.trim();
  if (needle.isEmpty) return true;
  return containsFolded(user.name, needle) || containsFolded(user.email, needle);
}

List<TrainingGroup> groupsOf(AppUser user, List<TrainingGroup> groups) {
  return [
    for (final group in groups)
      if (user.groupIds.contains(group.id)) group,
  ];
}
