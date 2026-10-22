import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../../app/club_config.dart';
import '../../../app/constants.dart';
import '../data/avatar_storage.dart';

/// Fotó készítése, galéria vagy eltávolítás. A kép négyzetes, 512 px JPEG.
Future<void> editAvatar({
  required BuildContext context,
  required String userId,
  required AvatarStorage storage,
  required Future<void> Function(String? photoUrl) save,
  required void Function(bool uploading) onUploading,
}) async {
  final action = await showModalBottomSheet<_AvatarAction>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Fotó készítése'),
              onTap: () => Navigator.of(context).pop(_AvatarAction.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Választás a galériából'),
              onTap: () => Navigator.of(context).pop(_AvatarAction.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Profilkép eltávolítása'),
              onTap: () => Navigator.of(context).pop(_AvatarAction.remove),
            ),
          ],
        ),
      );
    },
  );
  if (action == null || !context.mounted) return;
  if (action == _AvatarAction.remove) {
    onUploading(true);
    try {
      await storage.delete(userId);
      await save(null);
    } finally {
      onUploading(false);
    }
    return;
  }

  final source = action == _AvatarAction.camera
      ? ImageSource.camera
      : ImageSource.gallery;
  final picked = await ImagePicker().pickImage(source: source);
  if (picked == null || !context.mounted) return;
  final cropped = await ImageCropper().cropImage(
    sourcePath: picked.path,
    maxWidth: ClubConfig.avatarSize,
    maxHeight: ClubConfig.avatarSize,
    aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    compressFormat: ImageCompressFormat.jpg,
    compressQuality: ClubConfig.avatarQuality,
    uiSettings: [
      AndroidUiSettings(
        toolbarTitle: 'Vágás',
        toolbarColor: AppColors.burgundy,
        toolbarWidgetColor: AppColors.onPrimary,
        lockAspectRatio: true,
        initAspectRatio: CropAspectRatioPreset.square,
        aspectRatioPresets: const [CropAspectRatioPreset.square],
        cropStyle: CropStyle.circle,
      ),
      IOSUiSettings(
        title: 'Vágás',
        aspectRatioLockEnabled: true,
        resetAspectRatioEnabled: false,
        aspectRatioPresets: const [CropAspectRatioPreset.square],
        cropStyle: CropStyle.circle,
      ),
    ],
  );
  if (cropped == null) return;
  onUploading(true);
  try {
    final file = await _jpeg512(cropped.path);
    final url = await storage.upload(
      userId: userId,
      file: file,
      onProgress: (_) {},
    );
    await save(url);
  } finally {
    onUploading(false);
  }
}

Future<File> _jpeg512(String path) async {
  final directory = await getTemporaryDirectory();
  final target =
      '${directory.path}/avatar_${DateTime.now().microsecondsSinceEpoch}.jpg';
  final result = await FlutterImageCompress.compressAndGetFile(
    path,
    target,
    minWidth: ClubConfig.avatarSize,
    minHeight: ClubConfig.avatarSize,
    quality: ClubConfig.avatarQuality,
    format: CompressFormat.jpeg,
  );
  return File(result?.path ?? path);
}

enum _AvatarAction { camera, gallery, remove }
