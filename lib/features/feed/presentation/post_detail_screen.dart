import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../core/utils/hungarian_relative_time.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/presentation/auth_error_message.dart';
import '../data/feed_providers.dart';
import '../domain/post.dart';
import '../domain/post_access.dart';
import 'author_avatar.dart';
import 'post_card.dart';

/// Egy bejegyzés teljes szövege és a hozzászólásai.
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authGateProvider).asData?.value;
    final user = session is AuthSignedIn ? session.user : null;
    final post = ref.watch(postProvider(widget.postId));
    final comments = ref.watch(postCommentsProvider(widget.postId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bejegyzés'),
        actions: [
          post.maybeWhen(
            data: (value) {
              if (user == null ||
                  value == null ||
                  !canManagePost(user, value)) {
                return const SizedBox.shrink();
              }
              return PopupMenuButton<String>(
                tooltip: 'Műveletek',
                onSelected: (action) {
                  if (action == 'edit') {
                    context.push(AppRoutes.editPost(value.id));
                  } else if (action == 'delete') {
                    _delete(value.id);
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Szerkesztés')),
                  PopupMenuItem(value: 'delete', child: Text('Törlés')),
                ],
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: post.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text(authErrorMessage(error))),
              data: (value) {
                if (value == null) {
                  return const Center(
                    child: Text('A bejegyzés már nem elérhető.'),
                  );
                }
                return comments.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) =>
                      Center(child: Text(authErrorMessage(error))),
                  data: (items) => ListView(
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      if (user == null)
                        const SizedBox.shrink()
                      else
                        PostTile(
                          post: value,
                          user: user,
                          maxLines: null,
                          showMenu: false,
                          onOpen: () {},
                        ),
                      if (items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Még nincs hozzászólás.',
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        for (final comment in items)
                          _CommentTile(
                            comment: comment,
                            canDelete:
                                user != null && canDeleteComment(user, comment),
                            onDelete: () => _deleteComment(comment.id),
                          ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (user != null)
            Material(
              elevation: 8,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          maxLength: PostLimits.commentText,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          decoration: const InputDecoration(
                            hintText: 'Hozzászólás',
                          ),
                          onSubmitted: (_) => _send(user),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Küldés',
                        onPressed: _sending ? null : () => _send(user),
                        icon: const Icon(Icons.send),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _send(AppUser user) async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _sending) return;
    if (text.length > PostLimits.commentText) return;
    setState(() => _sending = true);
    try {
      await ref
          .read(postRepositoryProvider)
          .addComment(
            postId: widget.postId,
            authorId: user.id,
            authorName: user.name,
            authorPhotoUrl: _photo(user.photoUrl),
            text: text,
          );
      _commentController.clear();
      ref.invalidate(postCommentCountProvider(widget.postId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(String postId) async {
    final deleted = await deletePostFlow(context, ref, postId);
    if (deleted && mounted) context.pop();
  }

  Future<void> _deleteComment(String commentId) async {
    final confirmed = await confirmDelete(
      context,
      title: 'Törlöd a hozzászólást?',
      message: 'A hozzászólás véglegesen törlődik.',
    );
    if (!confirmed || !mounted) return;
    try {
      await ref
          .read(postRepositoryProvider)
          .deleteComment(postId: widget.postId, commentId: commentId);
      ref.invalidate(postCommentCountProvider(widget.postId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    }
  }

  String? _photo(String? photoUrl) {
    final value = photoUrl?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.canDelete,
    required this.onDelete,
  });

  final PostComment comment;
  final bool canDelete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AuthorAvatar(
            name: comment.authorName,
            photoUrl: comment.authorPhotoUrl,
            radius: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  comment.authorName,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  hungarianRelativeTime(comment.createdAt, DateTime.now()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(comment.text),
              ],
            ),
          ),
          if (canDelete)
            IconButton(
              tooltip: 'Hozzászólás törlése',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline),
            ),
        ],
      ),
    );
  }
}
