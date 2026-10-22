import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final avatarStorageProvider = Provider<AvatarStorage>((ref) {
  return AvatarStorage(FirebaseStorage.instance);
});

/// A profilkép mindig `users/{uid}/avatar.jpg`. Csere előtt a régi fájl törlődik.
class AvatarStorage {
  AvatarStorage(this._storage);

  final FirebaseStorage _storage;

  Reference _ref(String userId) => _storage.ref('users/$userId/avatar.jpg');

  Future<String> upload({
    required String userId,
    required File file,
    required void Function(double fraction) onProgress,
  }) async {
    final ref = _ref(userId);
    try {
      await ref.delete();
    } on FirebaseException {
      // Még nincs profilkép.
    }
    final task = ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
    final subscription = task.snapshotEvents.listen((snapshot) {
      final total = snapshot.totalBytes;
      if (total <= 0) return;
      onProgress(snapshot.bytesTransferred / total);
    });
    try {
      await task;
      onProgress(1);
      return await ref.getDownloadURL();
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> delete(String userId) async {
    try {
      await _ref(userId).delete();
    } on FirebaseException {
      // Már törölve.
    }
  }
}
