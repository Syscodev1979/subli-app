import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/training_group.dart';

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return FirestoreGroupRepository(
    FirebaseFirestore.instance,
    FirebaseFunctions.instanceFor(region: 'europe-west3'),
  );
});

final groupsProvider = StreamProvider<List<TrainingGroup>>((ref) {
  return ref.watch(groupRepositoryProvider).watchGroups();
});

abstract class GroupRepository {
  Stream<List<TrainingGroup>> watchGroups();

  Future<void> createGroup({
    required String name,
    required String color,
    required String description,
  });

  Future<void> updateGroup({
    required String id,
    required String name,
    required String color,
    required String description,
    required DateTime createdAt,
  });

  Future<void> deleteGroup(String id);
}

class FirestoreGroupRepository implements GroupRepository {
  FirestoreGroupRepository(this._firestore, this._functions);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _groups =>
      _firestore.collection('groups');

  @override
  Stream<List<TrainingGroup>> watchGroups() {
    return _groups.orderBy('name').snapshots().map((query) {
      return [
        for (final doc in query.docs) ?_group(doc),
      ];
    });
  }

  @override
  Future<void> createGroup({
    required String name,
    required String color,
    required String description,
  }) {
    return _groups.add({
      'name': name.trim(),
      'color': color,
      'description': description.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> updateGroup({
    required String id,
    required String name,
    required String color,
    required String description,
    required DateTime createdAt,
  }) {
    return _groups.doc(id).update({
      'name': name.trim(),
      'color': color,
      'description': description.trim(),
      'createdAt': Timestamp.fromDate(createdAt),
    });
  }

  @override
  Future<void> deleteGroup(String id) {
    return _functions.httpsCallable('deleteGroup').call({'groupId': id});
  }

  TrainingGroup? _group(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final name = data['name'];
    final color = data['color'];
    if (name is! String || color is! String) return null;
    final created = data['createdAt'];
    return TrainingGroup(
      id: doc.id,
      name: name,
      color: color,
      description: data['description'] is String
          ? data['description'] as String
          : '',
      createdAt: created is Timestamp ? created.toDate() : DateTime.now(),
    );
  }
}
