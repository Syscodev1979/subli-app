import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_user.dart';
import '../domain/user_repository.dart';
import '../domain/user_role.dart';
import '../domain/user_status.dart';
import 'app_user_mapper.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');

  @override
  Stream<AppUser?> watchUser(String id) {
    return _users.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AppUserMapper.fromDoc(doc);
    });
  }

  @override
  Future<void> createUser(AppUser user) {
    return _users.doc(user.id).set(AppUserMapper.toFirestore(user));
  }

  @override
  Stream<List<AppUser>> watchByStatus(UserStatus status) {
    return _users.where('status', isEqualTo: status.value).snapshots().map((
      query,
    ) {
      final users = query.docs.map(AppUserMapper.fromDoc).toList();
      users.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return users;
    });
  }

  @override
  Stream<List<AppUser>> watchActiveAthletes() {
    return watchByStatus(UserStatus.active).map((users) {
      return users.where((user) => user.role == UserRole.athlete).toList();
    });
  }

  @override
  Future<void> approveUser({
    required String userId,
    required UserRole currentRole,
    UserRole? assignedRole,
    List<String> childIds = const [],
  }) async {
    final resultingRole = assignedRole ?? currentRole;
    final linkedChildIds = resultingRole == UserRole.parent
        ? childIds.where((id) => id.isNotEmpty && id != userId).toSet().toList()
        : const <String>[];

    final batch = _firestore.batch();
    batch.update(_users.doc(userId), {
      'status': UserStatus.active.value,
      if (assignedRole != null) 'role': assignedRole.value,
      if (resultingRole == UserRole.parent) 'childIds': linkedChildIds,
    });
    for (final childId in linkedChildIds) {
      batch.update(_users.doc(childId), {
        'parentIds': FieldValue.arrayUnion([userId]),
      });
    }
    await batch.commit();
  }

  @override
  Future<void> rejectUser(String userId) {
    return _users.doc(userId).update({'status': UserStatus.rejected.value});
  }
}
