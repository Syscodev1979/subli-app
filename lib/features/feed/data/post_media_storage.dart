import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';

import '../domain/post.dart';
import 'media_prep.dart';
import 'storage_object_path.dart';

class MediaUploadCancelled implements Exception {
  const MediaUploadCancelled();
}

/// A `posts/{postId}/` mappába tölt fel, és onnan töröl.
class PostMediaStorage {
  PostMediaStorage(this._storage);

  final FirebaseStorage _storage;

  Future<PostMedia> upload({
    required String postId,
    required PreparedMedia prepared,
    required void Function(double fraction) onProgress,
    required bool Function() isCancelled,
  }) async {
    _ensureActive(isCancelled);
    final stamp = DateTime.now().microsecondsSinceEpoch;
    if (prepared.type == PostMediaType.image) {
      final url = await _put(
        path: 'posts/$postId/image_$stamp.jpg',
        file: prepared.file,
        contentType: 'image/jpeg',
        onProgress: onProgress,
        isCancelled: isCancelled,
      );
      return PostMedia(
        type: PostMediaType.image,
        url: url,
        width: prepared.width,
        height: prepared.height,
      );
    }

    final videoUrl = await _put(
      path: 'posts/$postId/video_$stamp.mp4',
      file: prepared.file,
      contentType: 'video/mp4',
      onProgress: (fraction) => onProgress(fraction * 0.9),
      isCancelled: isCancelled,
    );
    String? thumbUrl;
    final thumb = prepared.thumbFile;
    if (thumb != null) {
      thumbUrl = await _put(
        path: 'posts/$postId/video_${stamp}_thumb.jpg',
        file: thumb,
        contentType: 'image/jpeg',
        onProgress: (fraction) => onProgress(0.9 + fraction * 0.1),
        isCancelled: isCancelled,
      );
    }
    return PostMedia(
      type: PostMediaType.video,
      url: videoUrl,
      thumbUrl: thumbUrl,
      width: prepared.width,
      height: prepared.height,
      durationSec: prepared.durationSec,
    );
  }

  Future<void> deletePost(String postId) async {
    final listed = await _storage.ref('posts/$postId').listAll();
    for (final item in listed.items) {
      await item.delete();
    }
  }

  Future<void> deleteUrls(Iterable<String> urls) async {
    for (final url in urls) {
      await _storage.refFromURL(url).delete();
    }
  }

  /// A megmaradó letöltési URL-eken kívüli fájlokat törli.
  Future<void> deleteExcept(String postId, Iterable<String> keepUrls) async {
    final keep = {for (final url in keepUrls) ?storageObjectPath(url)};
    final listed = await _storage.ref('posts/$postId').listAll();
    for (final item in listed.items) {
      if (!keep.contains(item.fullPath)) {
        await item.delete();
      }
    }
  }

  Future<String> _put({
    required String path,
    required File file,
    required String contentType,
    required void Function(double fraction) onProgress,
    required bool Function() isCancelled,
  }) async {
    _ensureActive(isCancelled);
    final ref = _storage.ref(path);
    final task = ref.putFile(file, SettableMetadata(contentType: contentType));
    final subscription = task.snapshotEvents.listen((snapshot) {
      if (isCancelled()) {
        task.cancel();
        return;
      }
      final total = snapshot.totalBytes;
      if (total <= 0) return;
      onProgress(snapshot.bytesTransferred / total);
    });
    try {
      if (isCancelled()) {
        await task.cancel();
        throw const MediaUploadCancelled();
      }
      await task;
      onProgress(1);
      return await ref.getDownloadURL();
    } on FirebaseException catch (error) {
      if (error.code == 'canceled' || isCancelled()) {
        throw const MediaUploadCancelled();
      }
      rethrow;
    } finally {
      await subscription.cancel();
    }
  }

  void _ensureActive(bool Function() isCancelled) {
    if (isCancelled()) throw const MediaUploadCancelled();
  }
}
