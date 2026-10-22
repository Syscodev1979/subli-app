import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/app_user.dart';
import '../domain/child_request.dart';
import '../domain/user_role.dart';
import '../domain/user_status.dart';

/// `users` dokumentum és a domain modell közötti átalakítás.
class AppUserMapper {
  const AppUserMapper._();

  static Map<String, Object?> toFirestore(AppUser user) {
    return {
      'id': user.id,
      'name': user.name,
      'email': user.email,
      'role': user.role.value,
      'birthDate': _timestamp(user.birthDate),
      'photoUrl': user.photoUrl,
      'status': user.status.value,
      'childIds': user.childIds,
      'parentIds': user.parentIds,
      'childRequests': user.childRequests
          .map(
            (request) => {
              'name': request.name,
              'birthDate': Timestamp.fromDate(request.birthDate),
            },
          )
          .toList(),
      'createdAt': Timestamp.fromDate(user.createdAt),
      if (user.beltRank != null) 'beltRank': user.beltRank,
      if (user.requestedRole != null) 'requestedRole': user.requestedRole,
    };
  }

  static AppUser fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) {
      throw FormatException('Missing user document: ${doc.id}');
    }
    return AppUser(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      role: UserRole.parse(data['role'] as String? ?? ''),
      birthDate: _date(data['birthDate']),
      photoUrl: data['photoUrl'] as String?,
      status: UserStatus.parse(data['status'] as String? ?? ''),
      childIds: _stringList(data['childIds']),
      parentIds: _stringList(data['parentIds']),
      childRequests: _childRequests(data['childRequests']),
      createdAt:
          _date(data['createdAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      beltRank: data['beltRank'] is String ? data['beltRank'] as String : null,
      requestedRole: data['requestedRole'] is String
          ? data['requestedRole'] as String
          : null,
    );
  }

  static Timestamp? _timestamp(DateTime? date) {
    if (date == null) return null;
    return Timestamp.fromDate(date);
  }

  static DateTime? _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    return null;
  }

  static List<String> _stringList(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }

  static List<ChildRequest> _childRequests(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((item) {
      final map = Map<String, dynamic>.from(item);
      final birthDate = _date(map['birthDate']);
      if (birthDate == null) {
        throw FormatException('Child request is missing a birth date.');
      }
      return ChildRequest(
        name: (map['name'] as String? ?? '').trim(),
        birthDate: birthDate,
      );
    }).toList();
  }
}
