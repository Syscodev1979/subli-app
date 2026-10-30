import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/domain/user_role.dart';
import '../../chat/domain/club_member.dart';

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return FirestoreMemberRepository(FirebaseFirestore.instance);
});

/// A `members` gyűjtemény. A `users` dokumentumok nem olvashatók idegennek.
abstract class MemberRepository {
  Stream<ClubMember?> watchMember(String id);
}

class FirestoreMemberRepository implements MemberRepository {
  FirestoreMemberRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Stream<ClubMember?> watchMember(String id) {
    return _firestore.collection('members').doc(id).snapshots().map((doc) {
      final data = doc.data();
      if (data == null) return null;
      final role = _role(data['role']);
      if (role == null) return null;
      final photo = data['photoUrl'];
      final parents = data['parentIds'];
      final groups = data['groupIds'];
      return ClubMember(
        id: doc.id,
        name: data['name'] is String ? data['name'] as String : '',
        photoUrl: photo is String && photo.isNotEmpty ? photo : null,
        role: role,
        isMinor: data['isMinor'] == true,
        parentIds: parents is List
            ? parents.map((item) => item.toString()).toList()
            : const [],
        beltRank: data['beltRank'] is String
            ? data['beltRank'] as String
            : null,
        groupIds: groups is List
            ? groups.map((item) => item.toString()).toList()
            : const [],
      );
    });
  }

  UserRole? _role(Object? raw) {
    if (raw is! String) return null;
    for (final role in UserRole.values) {
      if (role.value == raw) return role;
    }
    return null;
  }
}
