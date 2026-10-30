import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      'requestedRole': FieldValue.delete(),
      'auditBy': FirebaseAuth.instance.currentUser?.uid,
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
    return _users.doc(userId).update({
      'status': UserStatus.rejected.value,
      'auditBy': FirebaseAuth.instance.currentUser?.uid,
    });
  }

  @override
  Future<void> updateOwnProfile({
    required String userId,
    String? name,
    DateTime? birthDate,
    String? photoUrl,
    bool clearPhoto = false,
  }) {
    return _users.doc(userId).update({
      if (name != null) 'name': name.trim(),
      if (birthDate != null) 'birthDate': Timestamp.fromDate(birthDate),
      if (clearPhoto) 'photoUrl': null,
      if (!clearPhoto && photoUrl != null) 'photoUrl': photoUrl,
    });
  }

  @override
  Future<void> updatePhotoUrl({
    required String userId,
    required String? photoUrl,
  }) {
    return _users.doc(userId).update({'photoUrl': photoUrl});
  }

  @override
  Future<void> setBeltRank({
    required String userId,
    required String? beltRank,
  }) {
    return _users.doc(userId).update({
      'beltRank': beltRank ?? FieldValue.delete(),
    });
  }

  @override
  Stream<List<AppUser>> watchAll() {
    return _users.snapshots().map((query) {
      final users = query.docs.map(AppUserMapper.fromDoc).toList();
      users.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return users;
    });
  }

  @override
  Future<void> saveMember({
    required String actorId,
    required AppUser before,
    required String name,
    required UserRole role,
    required UserStatus status,
    required String? beltRank,
    required List<String> groupIds,
    required DateTime? birthDate,
    required List<String> childIds,
    required List<String> parentIds,
  }) async {
    final sameGroups = _sameIds(before.groupIds, groupIds);
    final sensitive =
        before.role != role || before.status != status || !sameGroups;
    final batch = _firestore.batch();
    batch.update(_users.doc(before.id), {
      'name': name.trim(),
      'role': role.value,
      'status': status.value,
      'beltRank': beltRank ?? FieldValue.delete(),
      'groupIds': groupIds,
      'birthDate': birthDate == null
          ? FieldValue.delete()
          : Timestamp.fromDate(birthDate),
      'childIds': childIds,
      'parentIds': parentIds,
      if (sensitive) 'auditBy': actorId,
    });
    for (final id in before.childIds.where((id) => !childIds.contains(id))) {
      batch.update(_users.doc(id), {
        'parentIds': FieldValue.arrayRemove([before.id]),
      });
    }
    for (final id in childIds.where((id) => !before.childIds.contains(id))) {
      batch.update(_users.doc(id), {
        'parentIds': FieldValue.arrayUnion([before.id]),
      });
    }
    for (final id in before.parentIds.where((id) => !parentIds.contains(id))) {
      batch.update(_users.doc(id), {
        'childIds': FieldValue.arrayRemove([before.id]),
      });
    }
    for (final id in parentIds.where((id) => !before.parentIds.contains(id))) {
      batch.update(_users.doc(id), {
        'childIds': FieldValue.arrayUnion([before.id]),
      });
    }
    await batch.commit();
  }
}

bool _sameIds(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  final a = [...left]..sort();
  final b = [...right]..sort();
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
