import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_compress/video_compress.dart';

import '../domain/post.dart';

class MediaTooLong implements Exception {
  const MediaTooLong();
}

class MediaTooLarge implements Exception {
  const MediaTooLarge();
}

/// Feltöltésre kész, már tömörített fájl.
class PreparedMedia {
  const PreparedMedia({
    required this.type,
    required this.file,
    this.thumbFile,
    this.width,
    this.height,
    this.durationSec,
  });

  final PostMediaType type;
  final File file;
  final File? thumbFile;
  final int? width;
  final int? height;
  final int? durationSec;
}

/// Képet és videót tömörít, mielőtt a Storage-ba kerülne.
class MediaPrep {
  const MediaPrep();

  Future<PreparedMedia> prepareImage(String sourcePath) async {
    final target = await _tempFile('jpg');
    final compressed = await FlutterImageCompress.compressAndGetFile(
      sourcePath,
      target.path,
      quality: PostLimits.imageQuality,
      minWidth: PostLimits.imageLongestSide,
      minHeight: PostLimits.imageLongestSide,
      format: CompressFormat.jpeg,
    );
    final file = File(compressed?.path ?? target.path);
    if (!file.existsSync() || file.lengthSync() == 0) {
      throw const MediaTooLarge();
    }
    if (file.lengthSync() > PostLimits.maxImageBytes) {
      final smaller = await _tempFile('jpg');
      final retry = await FlutterImageCompress.compressAndGetFile(
        file.path,
        smaller.path,
        quality: 60,
        minWidth: PostLimits.imageLongestSide,
        minHeight: PostLimits.imageLongestSide,
        format: CompressFormat.jpeg,
      );
      final reduced = File(retry?.path ?? smaller.path);
      if (reduced.lengthSync() > PostLimits.maxImageBytes) {
        throw const MediaTooLarge();
      }
      final size = await _dimensions(await reduced.readAsBytes());
      return PreparedMedia(
        type: PostMediaType.image,
        file: reduced,
        width: size.$1,
        height: size.$2,
      );
    }
    final size = await _dimensions(await file.readAsBytes());
    return PreparedMedia(
      type: PostMediaType.image,
      file: file,
      width: size.$1,
      height: size.$2,
    );
  }

  Future<PreparedMedia> prepareVideo(String sourcePath) async {
    final info = await VideoCompress.getMediaInfo(sourcePath);
    final durationMs = info.duration ?? 0;
    if (durationMs > PostLimits.maxVideoSeconds * 1000) {
      throw const MediaTooLong();
    }
    final compressed = await VideoCompress.compressVideo(
      sourcePath,
      quality: VideoQuality.MediumQuality,
      deleteOrigin: false,
      includeAudio: true,
    );
    final file = compressed?.file;
    if (file == null || !file.existsSync()) {
      throw const MediaTooLarge();
    }
    if (file.lengthSync() > PostLimits.maxVideoBytes) {
      throw const MediaTooLarge();
    }
    final thumb = await VideoCompress.getFileThumbnail(
      file.path,
      quality: PostLimits.imageQuality,
      position: 0,
    );
    final seconds = (durationMs / 1000).round().clamp(
      1,
      PostLimits.maxVideoSeconds,
    );
    return PreparedMedia(
      type: PostMediaType.video,
      file: file,
      thumbFile: thumb,
      width: compressed?.width ?? info.width,
      height: compressed?.height ?? info.height,
      durationSec: seconds,
    );
  }

  Future<void> cancelVideo() => VideoCompress.cancelCompression();

  Future<File> _tempFile(String extension) async {
    final dir = await getTemporaryDirectory();
    final name =
        'gastroyal_${DateTime.now().microsecondsSinceEpoch}.$extension';
    return File('${dir.path}/$name');
  }

  Future<(int, int)> _dimensions(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = (image.width, image.height);
    image.dispose();
    codec.dispose();
    return size;
  }
}
