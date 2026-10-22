import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/club_colors.dart';
import '../../../app/constants.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_session.dart';
import '../data/feed_providers.dart';
import '../data/media_prep.dart';
import '../data/post_media_storage.dart';
import '../domain/post.dart';
import '../domain/post_access.dart';
import '../domain/post_category.dart';
import 'author_avatar.dart';
import 'category_style.dart';
import 'feed_chrome.dart';
import 'feed_controller.dart';
import 'feed_error_message.dart';
import 'media_consent.dart';
import 'press_scale.dart';

const _draftKey = 'composer_draft_text';

/// A hírfolyam sávjáról induló médiaválasztó.
enum ComposerLaunch { photo, video, camera }

/// Új bejegyzés, vagy egy meglévő szerkesztése.
///
/// Teljes magasságú, felül lekerekített lap. A hírfolyam a háttérben marad.
class PostEditorScreen extends ConsumerStatefulWidget {
  const PostEditorScreen({this.postId, this.launch, super.key});

  final String? postId;
  final ComposerLaunch? launch;

  @override
  ConsumerState<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends ConsumerState<PostEditorScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _images = <_MediaDraft>[];
  final _prep = const MediaPrep();
  final _picker = ImagePicker();
  _MediaDraft? _video;
  var _pinned = false;
  var _category = PostCategory.news;
  var _submitting = false;
  var _preparing = false;
  var _succeeded = false;
  var _cancelUpload = false;
  var _allowPop = false;
  var _closing = false;
  var _keepDraft = true;
  var _applying = false;
  var _loaded = false;
  double? _uploadProgress;
  String? _error;
  String _originalText = '';
  var _originalPinned = false;
  var _originalCategory = PostCategory.news;
  List<String?> _originalImageUrls = const [];
  String? _originalVideoUrl;
  Timer? _draftTimer;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_onOpened());
    });
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _textController
      ..removeListener(_onTextChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  bool get _inTest {
    return WidgetsBinding.instance.runtimeType.toString().contains('Test');
  }

  void _onTextChanged() {
    if (_applying) return;
    if (mounted) setState(() {});
    if (widget.postId != null || !_keepDraft) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 300), () {
      unawaited(_writeDraft());
    });
  }

  Future<void> _onOpened() async {
    if (!mounted || widget.postId != null) {
      _focusIfNeeded();
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = prefs.getString(_draftKey) ?? '';
      if (!mounted) return;
      if (draft.trim().isNotEmpty) {
        final keep = await _askContinueDraft();
        if (!mounted) return;
        if (keep == true) {
          _applying = true;
          _textController.text = draft;
          _textController.selection = TextSelection.collapsed(
            offset: draft.length,
          );
          _applying = false;
          setState(() {});
        } else if (keep == false) {
          await _clearDraft();
        }
      }
    } on Object {
      // Piszkozat nélkül is lehet írni.
    }
    if (!mounted) return;
    await _launchMediaIfNeeded();
    _focusIfNeeded();
  }

  void _focusIfNeeded() {
    if (!mounted || _inTest) return;
    _focusNode.requestFocus();
  }

  Future<void> _launchMediaIfNeeded() async {
    switch (widget.launch) {
      case ComposerLaunch.photo:
        await _pickGalleryPhotos();
      case ComposerLaunch.video:
        await _pickGalleryVideo();
      case ComposerLaunch.camera:
        await _openCamera();
      case null:
        return;
    }
  }

  Future<void> _writeDraft() async {
    if (!_keepDraft || widget.postId != null) return;
    final text = _textController.text;
    final prefs = await SharedPreferences.getInstance();
    if (text.trim().isEmpty) {
      await prefs.remove(_draftKey);
    } else {
      await prefs.setString(_draftKey, text);
    }
  }

  Future<void> _clearDraft() async {
    _keepDraft = false;
    _draftTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_draftKey);
  }

  bool get _canSubmit {
    if (_submitting || _preparing || _succeeded) return false;
    final text = _textController.text.trim();
    final hasMedia = _images.isNotEmpty || _video != null;
    if (text.isEmpty && !hasMedia) return false;
    if (_textController.text.length > PostLimits.postText) return false;
    final count = _images.length + (_video == null ? 0 : 1);
    if (_images.length > PostLimits.maxImages || count > PostLimits.maxMedia) {
      return false;
    }
    return true;
  }

  bool get _isDirty {
    if (widget.postId == null) {
      return _textController.text.trim().isNotEmpty ||
          _images.isNotEmpty ||
          _video != null ||
          _category != PostCategory.news;
    }
    if (_textController.text != _originalText ||
        _pinned != _originalPinned ||
        _category != _originalCategory) {
      return true;
    }
    if (_video?.prepared != null ||
        _images.any((item) => item.prepared != null)) {
      return true;
    }
    if (_video?.remote?.url != _originalVideoUrl) return true;
    if (_images.length != _originalImageUrls.length) return true;
    for (var i = 0; i < _images.length; i++) {
      if (_images[i].remote?.url != _originalImageUrls[i]) return true;
    }
    return false;
  }

  bool get _largeText {
    return _textController.text.length <= 120 &&
        _images.isEmpty &&
        _video == null;
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authGateProvider).asData?.value;
    final user = session is AuthSignedIn ? session.user : null;
    final postId = widget.postId;
    if (user == null) {
      return _frame(
        title: _title(isNew: postId == null),
        body: _spinner(),
      );
    }
    if (postId == null) {
      if (!user.role.canWritePosts) {
        return _frame(
          title: _title(isNew: true),
          body: _centered('Nincs jogosultságod ehhez a művelethez.'),
        );
      }
      return _editor(user, isNew: true);
    }

    final post = ref.watch(postProvider(postId));
    return post.when(
      loading: () => _frame(title: _title(isNew: false), body: _spinner()),
      error: (error, _) => _frame(
        title: _title(isNew: false),
        body: _centered(feedErrorMessage(error, saving: false)),
      ),
      data: (value) {
        if (value == null) {
          return _frame(
            title: _title(isNew: false),
            body: _centered('A bejegyzés már nem elérhető.'),
          );
        }
        if (!canManagePost(user, value)) {
          return _frame(
            title: _title(isNew: false),
            body: _centered('Nincs jogosultságod ehhez a művelethez.'),
          );
        }
        _loadOnce(value);
        return _editor(user, isNew: false);
      },
    );
  }

  void _loadOnce(Post post) {
    if (_loaded) return;
    _loaded = true;
    _applying = true;
    _textController.text = post.text;
    _applying = false;
    _pinned = post.pinned;
    _category = post.category;
    _originalText = post.text;
    _originalPinned = post.pinned;
    _originalCategory = post.category;
    _images
      ..clear()
      ..addAll(post.images.map(_MediaDraft.remote));
    final video = post.video;
    _video = video == null ? null : _MediaDraft.remote(video);
    _originalImageUrls = [for (final image in post.images) image.url];
    _originalVideoUrl = video?.url;
  }

  String _title({required bool isNew}) {
    return isNew ? 'Új bejegyzés' : 'Bejegyzés szerkesztése';
  }

  Widget _editor(AppUser user, {required bool isNew}) {
    final colors = ClubColors.of(context);
    return _frame(
      title: _title(isNew: isNew),
      publishing: _phase,
      onPublish: _canSubmit ? () => unawaited(_save(user, isNew: isNew)) : null,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
            children: [
              _AuthorBlock(user: user),
              const SizedBox(height: 12),
              CategoryChipRow(
                selected: _category,
                padding: EdgeInsets.zero,
                onSelected: (category) {
                  if (category == null || _submitting) return;
                  setState(() => _category = category);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                focusNode: _focusNode,
                minLines: 5,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textCapitalization: TextCapitalization.sentences,
                style: TextStyle(
                  fontSize: _largeText ? 24 : 18,
                  height: 1.4,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                decoration: InputDecoration(
                  hintText:
                      'Oszd meg a klub híreit, eredményeit, gondolataidat…',
                  hintStyle: TextStyle(
                    fontSize: _largeText ? 24 : 18,
                    height: 1.4,
                    color: colors.sheetMuted,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  counterText: '',
                ),
              ),
              if (_images.isNotEmpty || _video != null) ...[
                const SizedBox(height: 16),
                _DraftStrip(
                  images: _images,
                  video: _video,
                  onRemoveImage: (index) =>
                      setState(() => _images.removeAt(index)),
                  onRemoveVideo: () => setState(() => _video = null),
                  onReorder: _reorderImages,
                ),
              ],
            ],
          ),
          Positioned(
            right: 16,
            bottom: 8,
            child: _CharacterCounter(length: _textController.text.length),
          ),
        ],
      ),
      footer: _footer(),
      toolbar: _MediaToolbar(
        enabled: !_submitting && !_preparing,
        pinned: _pinned,
        onPhoto: _pickGalleryPhotos,
        onVideo: _pickGalleryVideo,
        onCamera: _openCamera,
        onPinned: (value) => setState(() => _pinned = value),
      ),
    );
  }

  Widget? _footer() {
    if (_error == null && !_preparing && _uploadProgress == null) return null;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_preparing)
            const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Tömörítés...'),
              ],
            ),
          if (_error != null)
            Text(_error!, style: TextStyle(color: scheme.error)),
          if (_uploadProgress != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => _cancelUpload = true,
                child: const Text('Megszakítás'),
              ),
            ),
        ],
      ),
    );
  }

  _PublishPhase get _phase {
    if (_succeeded) return _PublishPhase.success;
    if (_submitting) return _PublishPhase.uploading;
    return _PublishPhase.idle;
  }

  Widget _frame({
    required String title,
    required Widget body,
    _PublishPhase publishing = _PublishPhase.idle,
    VoidCallback? onPublish,
    Widget? footer,
    Widget? toolbar,
  }) {
    final colors = ClubColors.of(context);
    final animation =
        ModalRoute.of(context)?.animation ?? const AlwaysStoppedAnimation(1.0);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final isNew = widget.postId == null;
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || _submitting) return;
        unawaited(_requestClose());
      },
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
          children: [
            Positioned.fill(
              child: FadeTransition(
                opacity: animation,
                child: GestureDetector(
                  onTap: _submitting ? null : () => unawaited(_requestClose()),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.45),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: MediaQuery.paddingOf(context).top + 12,
              bottom: keyboard,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0, 1),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeOutCubic,
                      ),
                    ),
                child: Material(
                  key: const Key('composer-sheet'),
                  color: colors.sheet,
                  elevation: 8,
                  shadowColor: Colors.black54,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      const _Handle(),
                      _Header(
                        title: title,
                        isNew: isNew,
                        phase: publishing,
                        progress: _uploadProgress,
                        onClose: () => unawaited(_requestClose()),
                        onPublish: onPublish,
                      ),
                      Expanded(child: body),
                      ?footer,
                      ?toolbar,
                      if (keyboard == 0)
                        SizedBox(height: MediaQuery.paddingOf(context).bottom),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _spinner() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _centered(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  Future<void> _requestClose() async {
    if (_closing || _submitting || !mounted) return;
    if (!_isDirty) {
      await _finishClose();
      return;
    }
    _closing = true;
    final colors = ClubColors.of(context);
    final isNew = widget.postId == null;
    final discard = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: colors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _ConfirmSheet(
          title: isNew ? 'Elveted a bejegyzést?' : 'Elveted a módosításokat?',
          primary: 'Elvetés',
          primaryColor: const Color(0xFFC62828),
          secondary: 'Folytatom a szerkesztést',
        );
      },
    );
    _closing = false;
    if (!mounted || discard != true) return;
    if (isNew) await _clearDraft();
    await _finishClose();
  }

  Future<bool?> _askContinueDraft() {
    final colors = ClubColors.of(context);
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: colors.sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _ConfirmSheet(
          title: 'Folytatod a piszkozatot?',
          primary: 'Folytatom',
          primaryColor: AppColors.burgundy,
          secondary: 'Elvetem',
        );
      },
    );
  }

  Future<void> _finishClose() async {
    if (!mounted) return;
    setState(() => _allowPop = true);
    await Future<void>.delayed(const Duration(milliseconds: 16));
    if (!mounted) return;
    context.pop();
  }

  Future<void> _save(AppUser user, {required bool isNew}) async {
    final text = _textController.text.trim();
    final hasMedia = _images.isNotEmpty || _video != null;
    if (text.isEmpty && !hasMedia) return;
    if (_textController.text.length > PostLimits.postText) {
      setState(() => _error = 'A bejegyzés legfeljebb 5000 karakter lehet.');
      return;
    }
    setState(() {
      _submitting = true;
      _cancelUpload = false;
      _uploadProgress =
          _images.any((item) => item.prepared != null) ||
              _video?.prepared != null
          ? 0
          : null;
      _error = null;
    });
    final repository = ref.read(postRepositoryProvider);
    final needsStorage =
        !isNew ||
        _images.any((item) => item.prepared != null) ||
        _video?.prepared != null;
    final storage = needsStorage
        ? PostMediaStorage(FirebaseStorage.instance)
        : null;
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
          category: _category,
          media: media,
        );
      } else {
        await repository.updatePost(
          postId: postId,
          text: text,
          pinned: _pinned,
          category: _category,
          media: media,
        );
        await storage?.deleteExcept(postId, [
          for (final item in media) ...[item.url, ?item.thumbUrl],
        ]);
      }
      final chrome = ref.read(feedChromeProvider);
      final scroll = chrome.scrollToTopAndRefresh;
      if (scroll != null) {
        await scroll();
      } else {
        await ref.read(feedControllerProvider.notifier).refresh();
      }
      if (isNew) await _clearDraft();
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      setState(() {
        _succeeded = true;
        _allowPop = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(isNew ? 'Bejegyzés közzétéve' : 'Bejegyzés mentve'),
        ),
      );
    } on MediaUploadCancelled {
      await storage?.deleteUrls(freshUrls);
      if (mounted) {
        setState(() => _error = 'A feltöltés megszakadt.');
      }
    } catch (error) {
      await storage?.deleteUrls(freshUrls);
      if (mounted) {
        setState(() => _error = feedErrorMessage(error, saving: true));
      }
    } finally {
      if (mounted && !_succeeded) {
        setState(() {
          _submitting = false;
          _uploadProgress = null;
        });
      }
    }
  }

  Future<List<PostMedia>> _uploadDrafts({
    required PostMediaStorage? storage,
    required String postId,
    required List<String> freshUrls,
  }) async {
    final drafts = [..._images, ?_video];
    if (drafts.isEmpty) return const [];
    final localCount = drafts.where((draft) => draft.prepared != null).length;
    final uploaded = <PostMedia>[];
    var finished = 0;
    for (final draft in drafts) {
      final remote = draft.remote;
      if (remote != null) {
        uploaded.add(remote);
        continue;
      }
      final prepared = draft.prepared;
      if (prepared == null || storage == null) continue;
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

enum _PublishPhase { idle, uploading, success }

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

  int? get durationSec => prepared?.durationSec ?? remote?.durationSec;
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: ClubColors.of(context).sheetMuted.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.isNew,
    required this.phase,
    required this.progress,
    required this.onClose,
    required this.onPublish,
  });

  final String title;
  final bool isNew;
  final _PublishPhase phase;
  final double? progress;
  final VoidCallback onClose;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          IconButton(
            tooltip: 'Mégse',
            onPressed: onClose,
            icon: const Icon(Icons.close),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _PublishButton(
              isNew: isNew,
              phase: phase,
              progress: progress,
              onPressed: onPublish,
            ),
          ),
        ],
      ),
    );
  }
}

class _PublishButton extends StatelessWidget {
  const _PublishButton({
    required this.isNew,
    required this.phase,
    required this.progress,
    required this.onPressed,
  });

  final bool isNew;
  final _PublishPhase phase;
  final double? progress;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = ClubColors.of(context);
    final active = onPressed != null || phase != _PublishPhase.idle;
    final label = isNew ? 'Közzététel' : 'Mentés';
    final percent = ((progress ?? 0) * 100).round();
    final foreground = active ? AppColors.onPrimary : colors.onPublishDisabled;
    final child = switch (phase) {
      _PublishPhase.success => Icon(Icons.check_rounded, color: foreground),
      _PublishPhase.uploading => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foreground,
              value: progress,
            ),
          ),
          const SizedBox(width: 8),
          Text(progress == null ? '$label…' : '$label… $percent%'),
        ],
      ),
      _PublishPhase.idle => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.send_rounded, size: 16, color: foreground),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    };
    return PressScale(
      onTap: onPressed,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 168, minHeight: 36),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: active ? colors.publishGradient : null,
            color: active ? null : colors.publishDisabled,
            borderRadius: BorderRadius.circular(24),
            boxShadow: onPressed == null
                ? null
                : [
                    BoxShadow(
                      color: AppColors.burgundy.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: DefaultTextStyle(
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                maxLines: 1,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthorBlock extends StatelessWidget {
  const _AuthorBlock({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final colors = ClubColors.of(context);
    return Row(
      children: [
        _GoldRing(
          diameter: 48,
          child: AuthorAvatar(
            name: user.name,
            photoUrl: user.photoUrl,
            radius: 24,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.goldSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.groups_outlined,
                        size: 16,
                        color: colors.onGoldSurface,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${AppInfo.clubName} · minden tag',
                          maxLines: 2,
                          style: TextStyle(
                            color: colors.onGoldSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GoldRing extends StatelessWidget {
  const _GoldRing({required this.diameter, required this.child});

  final double diameter;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter + 4,
      height: diameter + 4,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: ClubColors.of(context).gold, width: 1.5),
      ),
      child: child,
    );
  }
}

class _CharacterCounter extends StatelessWidget {
  const _CharacterCounter({required this.length});

  final int length;

  @override
  Widget build(BuildContext context) {
    final colors = ClubColors.of(context);
    final max = PostLimits.postText;
    final remaining = max - length;
    final color = length > max
        ? Theme.of(context).colorScheme.error
        : length >= (max * 0.9).round()
        ? colors.gold
        : colors.sheetMuted;
    return Semantics(
      label: 'Hátralévő karakterek: $remaining',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: (length / max).clamp(0, 1).toDouble(),
              strokeWidth: 3,
              color: color,
              backgroundColor: color.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$remaining',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _MediaToolbar extends StatelessWidget {
  const _MediaToolbar({
    required this.enabled,
    required this.pinned,
    required this.onPhoto,
    required this.onVideo,
    required this.onCamera,
    required this.onPinned,
  });

  final bool enabled;
  final bool pinned;
  final VoidCallback onPhoto;
  final VoidCallback onVideo;
  final VoidCallback onCamera;
  final ValueChanged<bool> onPinned;

  @override
  Widget build(BuildContext context) {
    final colors = ClubColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _MediaTool(
                    label: 'Fotó',
                    icon: Icons.photo_outlined,
                    foreground: colors.photo,
                    background: colors.photoBackground,
                    onTap: enabled ? onPhoto : null,
                  ),
                  const SizedBox(width: 8),
                  _MediaTool(
                    label: 'Videó',
                    icon: Icons.videocam_outlined,
                    foreground: colors.video,
                    background: colors.videoBackground,
                    onTap: enabled ? onVideo : null,
                  ),
                  const SizedBox(width: 8),
                  _MediaTool(
                    label: 'Kamera',
                    icon: Icons.photo_camera_outlined,
                    foreground: colors.camera,
                    background: colors.cameraBackground,
                    onTap: enabled ? onCamera : null,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          _PinButton(pinned: pinned, onChanged: enabled ? onPinned : null),
        ],
      ),
    );
  }
}

class _MediaTool extends StatelessWidget {
  const _MediaTool({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: foreground, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinButton extends StatelessWidget {
  const _PinButton({required this.pinned, required this.onChanged});

  final bool pinned;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = ClubColors.of(context);
    return Tooltip(
      message: pinned ? 'A bejegyzés a hírfolyam tetején marad' : 'Kitűzés',
      child: PressScale(
        onTap: onChanged == null ? null : () => onChanged!(!pinned),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: pinned ? colors.goldSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: pinned
                ? null
                : Border.all(color: colors.sheetMuted.withValues(alpha: 0.35)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  pinned ? Icons.push_pin : Icons.push_pin_outlined,
                  color: colors.gold,
                  size: 20,
                ),
                if (pinned) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Kitűzve',
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      color: colors.onGoldSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DraftStrip extends StatelessWidget {
  const _DraftStrip({
    required this.images,
    required this.video,
    required this.onRemoveImage,
    required this.onRemoveVideo,
    required this.onReorder,
  });

  final List<_MediaDraft> images;
  final _MediaDraft? video;
  final ValueChanged<int> onRemoveImage;
  final VoidCallback onRemoveVideo;
  final void Function(int from, int to) onReorder;

  @override
  Widget build(BuildContext context) {
    final count = images.length + (video == null ? 0 : 1);
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index >= images.length) {
            return _Thumb(
              draft: video!,
              onRemove: onRemoveVideo,
              removeTooltip: 'Videó törlése',
              video: true,
            );
          }
          return DragTarget<int>(
            onAcceptWithDetails: (details) => onReorder(details.data, index),
            builder: (context, candidate, rejected) {
              return LongPressDraggable<int>(
                data: index,
                feedback: _Thumb(draft: images[index], onRemove: () {}),
                child: _Thumb(
                  draft: images[index],
                  onRemove: () => onRemoveImage(index),
                  removeTooltip: 'Kép törlése',
                  highlighted: candidate.isNotEmpty,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({
    required this.draft,
    required this.onRemove,
    this.removeTooltip = '',
    this.video = false,
    this.highlighted = false,
  });

  final _MediaDraft draft;
  final VoidCallback onRemove;
  final String removeTooltip;
  final bool video;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final seconds = draft.durationSec;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image(image: draft.preview, fit: BoxFit.cover),
            if (highlighted) const ColoredBox(color: Color(0x446B1E2E)),
            if (video)
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            if (video && seconds != null)
              Positioned(
                left: 4,
                bottom: 4,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x99000000),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Text(
                      _clock(seconds),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            if (removeTooltip.isNotEmpty)
              Positioned(
                top: 4,
                right: 4,
                child: Tooltip(
                  message: removeTooltip,
                  child: Material(
                    color: const Color(0x99000000),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onRemove,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

String _clock(int seconds) {
  final minutes = seconds ~/ 60;
  final rest = seconds % 60;
  return '$minutes:${rest.toString().padLeft(2, '0')}';
}

class _ConfirmSheet extends StatelessWidget {
  const _ConfirmSheet({
    required this.title,
    required this.primary,
    required this.primaryColor,
    required this.secondary,
  });

  final String title;
  final String primary;
  final Color primaryColor;
  final String secondary;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _Handle(),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: AppColors.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(primary),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(secondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
