import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/data/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_session.dart';
import '../data/feed_providers.dart';
import '../domain/post.dart';
import '../domain/post_access.dart';
import 'feed_controller.dart';
import 'feed_error_message.dart';

/// Új bejegyzés, vagy egy meglévő szerkesztése.
class PostEditorScreen extends ConsumerStatefulWidget {
  const PostEditorScreen({this.postId, super.key});

  final String? postId;

  @override
  ConsumerState<PostEditorScreen> createState() => _PostEditorScreenState();
}

class _PostEditorScreenState extends ConsumerState<PostEditorScreen> {
  final _textController = TextEditingController();
  var _pinned = false;
  var _submitting = false;
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
              onPressed: _submitting ? null : () => _save(user, isNew: isNew),
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
    if (text.isEmpty) {
      setState(() => _error = 'Írd meg a bejegyzést.');
      return;
    }
    if (text.length > PostLimits.postText) {
      setState(() => _error = 'A bejegyzés legfeljebb 5000 karakter lehet.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    final repository = ref.read(postRepositoryProvider);
    try {
      if (isNew) {
        await repository.createPost(
          authorId: user.id,
          authorName: user.name,
          authorPhotoUrl: _photo(user.photoUrl),
          text: text,
          pinned: _pinned,
        );
      } else {
        await repository.updatePost(
          postId: widget.postId!,
          text: text,
          pinned: _pinned,
        );
      }
      await ref.read(feedControllerProvider.notifier).refresh();
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        setState(() => _error = feedErrorMessage(error, saving: true));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String? _photo(String? photoUrl) {
    final value = photoUrl?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }
}
