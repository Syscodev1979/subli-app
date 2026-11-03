import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/content_report.dart';

/// A tesztben és kijelentkezve üres. A Firebase nélkül nem kérdez.
final blockedIdsProvider = StreamProvider<Set<String>>((ref) {
  if (Firebase.apps.isEmpty) return const Stream.empty();
  final session = ref.watch(authGateProvider).asData?.value;
  if (session is! AuthSignedIn) return const Stream.empty();
  return ref.watch(safetyRepositoryProvider).watchBlockedIds(session.user.id);
});

final safetyRepositoryProvider = Provider<SafetyRepository>((ref) {
  return SafetyRepository(
    FirebaseFirestore.instance,
    FirebaseFunctions.instanceFor(region: 'europe-west3'),
  );
});

class SafetyRepository {
  SafetyRepository(this._db, this._functions);

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Stream<Set<String>> watchBlockedIds(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('blocks')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toSet());
  }

  Future<void> blockUser(String uid, String blockedId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('blocks')
        .doc(blockedId)
        .set({'createdAt': FieldValue.serverTimestamp()});
  }

  Future<void> unblockUser(String uid, String blockedId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('blocks')
        .doc(blockedId)
        .delete();
  }

  Future<void> report({
    required String reporterId,
    required ReportTargetType targetType,
    required String targetId,
    required String targetAuthorId,
    required String targetPath,
    required ReportReason reason,
    required String details,
    required String snapshot,
  }) {
    return _db.collection('reports').add({
      'reporterId': reporterId,
      'targetType': targetType.name,
      'targetId': targetId,
      'targetAuthorId': targetAuthorId,
      'targetPath': targetPath,
      'reason': reason.value,
      'details': details.trim(),
      'snapshot': snapshot.length > 500 ? snapshot.substring(0, 500) : snapshot,
      'status': 'open',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<ContentReport>> watchReports() {
    return _db
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_report).toList());
  }

  Future<void> resolveReport({
    required String reportId,
    required String action,
  }) {
    return _functions.httpsCallable('resolveReport').call({
      'reportId': reportId,
      'action': action,
    });
  }

  Future<void> deleteOwnAccount() {
    return _functions.httpsCallable('deleteOwnAccount').call();
  }

  ContentReport _report(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final created = data['createdAt'];
    return ContentReport(
      id: doc.id,
      reporterId: data['reporterId'] as String? ?? '',
      targetType: data['targetType'] as String? ?? '',
      targetId: data['targetId'] as String? ?? '',
      targetAuthorId: data['targetAuthorId'] as String? ?? '',
      targetPath: data['targetPath'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      details: data['details'] as String? ?? '',
      snapshot: data['snapshot'] as String? ?? '',
      status: data['status'] as String? ?? 'open',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }
}
