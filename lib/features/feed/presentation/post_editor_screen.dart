import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../auth/data/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_session.dart';
import '../data/feed_providers.dart';
import '../data/media_prep.dart';
import '../data/post_media_storage.dart';
import '../domain/post.dart';
import '../domain/post_access.dart';
import 'feed_controller.dart';
import 'feed_error_message.dart';
import 'media_consent.dart';

/// Új bejegyzés, vagy egy meglévő szerkesztése.
class PostEditorScreen extends ConsumerStatefulWidget {
  const PostEditorScreen({this.postId, super.key});

  final String? postId;

  @override
  ConsumerState<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends ConsumerState<PostEditorScreen> {
  final _textController = TextEditingController();
  final _images = <_MediaDraft>[];
  final _prep = const MediaPrep();
  final _picker = ImagePicker();
  _MediaDraft? _video;
  var _pinned = false;
  var _submitting = false;
  var _preparing = false;
  var _cancelUpload = false;
  double? _uploadProgress;
  var _loaded = false;
  String? _error;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authGateProvider).asData?.value;
    final user = session is AuthSignedIn ? session.user : null;
    final postId = widget.postId;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (postId == null) {
      if (!user.role.canWritePosts) return _denied();
      return _scaffold(user, isNew: true);
    }

    final post = ref.watch(postProvider(postId));
    return post.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) =>
          _messageScaffold(feedErrorMessage(error, saving: false)),
      data: (value) {
        if (value == null) {
          return _messageScaffold('A bejegyzés már nem elérhető.');
        }
        if (!canManagePost(user, value)) return _denied();
        _loadOnce(value);
        return _scaffold(user, isNew: false);
      },
    );
  }

  void _loadOnce(Post post) {
    if (_loaded) return;
    _loaded = true;
    _textController.text = post.text;
    _pinned = post.pinned;
    _images
      ..clear()
      ..addAll(post.images.map(_MediaDraft.remote));
    final video = post.video;
    _video = video == null ? null : _MediaDraft.remote(video);
  }

  Widget _scaffold(AppUser user, {required bool isNew}) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isNew ? 'Új bejegyzés' : 'Bejegyzés szerkesztése'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            TextField(
              controller: _textController,
              maxLength: PostLimits.postText,
              minLines: 6,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Szöveg',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            _MediaButtons(
              enabled: !_submitting && !_preparing,
              onPhoto: _pickGalleryPhotos,
              onVideo: _pickGalleryVideo,
              onCamera: _openCamera,
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ImageDraftGrid(
                images: _images,
                onRemove: (index) => setState(() => _images.removeAt(index)),
                onReorder: _reorderImages,
              ),
            ],
            if (_video != null) ...[
              const SizedBox(height: 12),
              _VideoDraft(
                draft: _video!,
                onRemove: () => setState(() => _video = null),
              ),
            ],
            if (_uploadProgress != null) ...[
              const SizedBox(height: 16),
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('${(_uploadProgress! * 100).round()}%'),
                  const Spacer(),
                  TextButton(
                    onPressed: () => _cancelUpload = true,
                    child: const Text('Megszakítás'),
                  ),
                ],
              ),
            ] else if (_preparing) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              const Text('Tömörítés...'),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Kitűzés'),
              value: _pinned,
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _pinned = value),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _submitting || _preparing
                  ? null
                  : () => _save(user, isNew: isNew),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isNew ? 'Közzététel' : 'Mentés'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _denied() {
    return _messageScaffold('Nincs jogosultságod ehhez a művelethez.');
  }

  Widget _messageScaffold(String message) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.postId == null ? 'Új bejegyzés' : 'Bejegyzés szerkesztése',
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }

  Future<void> _save(AppUser user, {required bool isNew}) async {
    final text = _textController.text.trim();
    final hasMedia = _images.isNotEmpty || _video != null;
    if (text.isEmpty && !hasMedia) {
      setState(
        () =>
            _error = 'Írd meg a bejegyzést, vagy adj hozzá fotót vagy videót.',
      );
      return;
    }
    if (text.length > PostLimits.postText) {
      setState(() => _error = 'A bejegyzés legfeljebb 5000 karakter lehet.');
      return;
    }
    if (_images.length > PostLimits.maxImages ||
        _images.length + (_video == null ? 0 : 1) > PostLimits.maxMedia) {
      setState(() => _error = 'Egy bejegyzéshez legfeljebb 10 fájl adható.');
      return;
    }
    setState(() {
      _submitting = true;
      _cancelUpload = false;
      _uploadProgress = null;
      _error = null;
    });
    final repository = ref.read(postRepositoryProvider);
    final storage = PostMediaStorage(FirebaseStorage.instance);
    final postId = isNew ? repository.reservePostId() : widget.postId!;
    final freshUrls = <String>[];
    try {
      final media = await _uploadDrafts(
        storage: storage,
        postId: postId,
        freshUrls: freshUrls,
      );
      if (_cancelUpload) throw const MediaUploadCancelled();
      if (isNew) {
        await repository.createPost(
          postId: postId,
          authorId: user.id,
          authorName: user.name,
          authorPhotoUrl: _photo(user.photoUrl),
          text: text,
          pinned: _pinned,
          media: media,
        );
      } else {
        await repository.updatePost(
          postId: postId,
          text: text,
          pinned: _pinned,
          media: media,
        );
        await storage.deleteExcept(postId, [
          for (final item in media) ...[item.url, ?item.thumbUrl],
        ]);
      }
      await ref.read(feedControllerProvider.notifier).refresh();
      if (mounted) context.pop();
    } on MediaUploadCancelled {
      await storage.deleteUrls(freshUrls);
      if (mounted) {
        setState(() => _error = 'A feltöltés megszakadt.');
      }
    } catch (error) {
      await storage.deleteUrls(freshUrls);
      if (mounted) {
        setState(() => _error = feedErrorMessage(error, saving: true));
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
          _uploadProgress = null;
        });
      }
    }
  }

  Future<List<PostMedia>> _uploadDrafts({
    required PostMediaStorage storage,
    required String postId,
    required List<String> freshUrls,
  }) async {
    final drafts = [..._images, ?_video];
    final localCount = drafts.where((draft) => draft.prepared != null).length;
    final uploaded = <PostMedia>[];
    var finished = 0;
    if (localCount > 0 && mounted) {
      setState(() => _uploadProgress = 0);
    }
    for (final draft in drafts) {
      final remote = draft.remote;
      if (remote != null) {
        uploaded.add(remote);
        continue;
      }
      final prepared = draft.prepared;
      if (prepared == null) continue;
      final media = await storage.upload(
        postId: postId,
        prepared: prepared,
        isCancelled: () => _cancelUpload,
        onProgress: (fraction) {
          if (!mounted) return;
          setState(() => _uploadProgress = (finished + fraction) / localCount);
        },
      );
      freshUrls.add(media.url);
      if (media.thumbUrl != null) freshUrls.add(media.thumbUrl!);
      uploaded.add(media);
      finished++;
    }
    return uploaded;
  }

  Future<void> _pickGalleryPhotos() => _pickImages(ImageSource.gallery);

  Future<void> _pickGalleryVideo() => _pickVideo(ImageSource.gallery);

  Future<void> _openCamera() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Fotó'),
                onTap: () => Navigator.of(context).pop('photo'),
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Videó'),
                onTap: () => Navigator.of(context).pop('video'),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    if (choice == 'photo') {
      await _pickImages(ImageSource.camera);
    } else {
      await _pickVideo(ImageSource.camera);
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    if (!await ensureMediaConsent(context)) return;
    final room =
        PostLimits.maxMedia - _images.length - (_video == null ? 0 : 1);
    final imageRoom = PostLimits.maxImages - _images.length;
    final allowed = room < imageRoom ? room : imageRoom;
    if (allowed <= 0) {
      setState(() => _error = 'Egy bejegyzéshez legfeljebb 10 kép adható.');
      return;
    }
    if (!mounted) return;
    final List<XFile> files;
    if (source == ImageSource.gallery) {
      files = await _picker.pickMultiImage(limit: allowed);
    } else {
      final file = await _picker.pickImage(source: ImageSource.camera);
      files = file == null ? <XFile>[] : [file];
    }
    if (files.isEmpty || !mounted) return;
    setState(() {
      _preparing = true;
      _error = null;
    });
    try {
      for (final file in files.take(allowed)) {
        final prepared = await _prep.prepareImage(file.path);
        if (!mounted) return;
        setState(() => _images.add(_MediaDraft.local(prepared)));
      }
      if (files.length > allowed && mounted) {
        setState(() => _error = 'Egy bejegyzéshez legfeljebb 10 kép adható.');
      }
    } on MediaTooLarge {
      if (mounted) {
        setState(() => _error = 'A kép tömörítés után is nagyobb 10 MB-nál.');
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = feedErrorMessage(error, saving: true));
      }
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    if (_video != null) {
      setState(() => _error = 'Egy bejegyzéshez egy videó adható.');
      return;
    }
    if (_images.length >= PostLimits.maxMedia) {
      setState(() => _error = 'Egy bejegyzéshez legfeljebb 10 fájl adható.');
      return;
    }
    if (!await ensureMediaConsent(context)) return;
    if (!mounted) return;
    final file = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(minutes: 3),
    );
    if (file == null || !mounted) return;
    setState(() {
      _preparing = true;
      _error = null;
    });
    try {
      final prepared = await _prep.prepareVideo(file.path);
      if (!mounted) return;
      setState(() => _video = _MediaDraft.local(prepared));
    } on MediaTooLong {
      if (mounted) {
        setState(() => _error = 'A videó legfeljebb 3 perc lehet.');
      }
    } on MediaTooLarge {
      if (mounted) {
        setState(
          () => _error = 'A videó tömörítés után is nagyobb 100 MB-nál.',
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = feedErrorMessage(error, saving: true));
      }
    } finally {
      if (mounted) setState(() => _preparing = false);
    }
  }

  void _reorderImages(int from, int to) {
    if (from == to || from < 0 || to < 0) return;
    if (from >= _images.length || to >= _images.length) return;
    setState(() {
      final item = _images.removeAt(from);
      _images.insert(to, item);
    });
  }

  String? _photo(String? photoUrl) {
    final value = photoUrl?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }
}

class _MediaDraft {
  const _MediaDraft.remote(this.remote) : prepared = null;
  const _MediaDraft.local(this.prepared) : remote = null;

  final PostMedia? remote;
  final PreparedMedia? prepared;

  ImageProvider<Object> get preview {
    final local = prepared;
    if (local != null) {
      final thumb = local.thumbFile;
      return FileImage(thumb ?? local.file);
    }
    final item = remote!;
    return CachedNetworkImageProvider(item.thumbUrl ?? item.url);
  }
}

class _MediaButtons extends StatelessWidget {
  const _MediaButtons({
    required this.enabled,
    required this.onPhoto,
    required this.onVideo,
    required this.onCamera,
  });

  final bool enabled;
  final VoidCallback onPhoto;
  final VoidCallback onVideo;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled ? onPhoto : null,
            icon: const Icon(Icons.photo_outlined),
            label: const Text('Fotó'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled ? onVideo : null,
            icon: const Icon(Icons.videocam_outlined),
            label: const Text('Videó'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: enabled ? onCamera : null,
            icon: const Icon(Icons.photo_camera_outlined),
            label: const Text('Kamera'),
          ),
        ),
      ],
    );
  }
}

class _ImageDraftGrid extends StatelessWidget {
  const _ImageDraftGrid({
    required this.images,
    required this.onRemove,
    required this.onReorder,
  });

  final List<_MediaDraft> images;
  final ValueChanged<int> onRemove;
  final void Function(int from, int to) onReorder;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return DragTarget<int>(
          onAcceptWithDetails: (details) => onReorder(details.data, index),
          builder: (context, candidate, rejected) {
            return LongPressDraggable<int>(
              data: index,
              feedback: SizedBox(
                width: 96,
                height: 96,
                child: Image(image: images[index].preview, fit: BoxFit.cover),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image(image: images[index].preview, fit: BoxFit.cover),
                  if (candidate.isNotEmpty)
                    const ColoredBox(color: Color(0x446B1E2E)),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: IconButton(
                      tooltip: 'Kép törlése',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onRemove(index),
                      icon: const Icon(Icons.close, size: 16),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0x99000000),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _VideoDraft extends StatelessWidget {
  const _VideoDraft({required this.draft, required this.onRemove});

  final _MediaDraft draft;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Image(image: draft.preview, fit: BoxFit.cover),
        ),
        const Positioned.fill(
          child: IgnorePointer(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            tooltip: 'Videó törlése',
            onPressed: onRemove,
            icon: const Icon(Icons.close),
            color: Colors.white,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0x99000000),
            ),
          ),
        ),
      ],
    );
  }
}
