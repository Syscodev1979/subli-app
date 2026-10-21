import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../core/utils/hungarian_relative_time.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_error_message.dart';
import '../data/feed_providers.dart';
import '../domain/post.dart';
import '../domain/post_access.dart';
import '../domain/post_repository.dart';
import 'author_avatar.dart';
import 'feed_controller.dart';

/// Törlés előtt megerősítés. Igaz, ha a felhasználó a törlést választotta.
Future<bool> confirmDelete(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Mégse'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Törlés'),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

Future<bool> deletePostFlow(
  BuildContext context,
  WidgetRef ref,
  String postId,
) async {
  final confirmed = await confirmDelete(
    context,
    title: 'Törlöd a bejegyzést?',
    message: 'A bejegyzés és a hozzászólásai véglegesen törlődnek.',
  );
  if (!confirmed || !context.mounted) return false;
  try {
    await ref.read(postRepositoryProvider).deletePost(postId);
    await ref.read(feedControllerProvider.notifier).refresh();
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
    }
    return false;
  }
}

/// A pipázók listája.
Future<void> showChecksSheet(
  BuildContext context,
  PostRepository repository,
  String postId,
) async {
  final future = repository.fetchChecks(postId);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: SizedBox(
          height: 360,
          child: FutureBuilder<List<PostCheck>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(authErrorMessage(snapshot.error!)),
                  ),
                );
              }
              final checks = snapshot.data ?? const <PostCheck>[];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Text(
                      'Kik pipázták',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: checks.isEmpty
                        ? const Center(child: Text('Még senki nem pipázta.'))
                        : ListView.builder(
                            itemCount: checks.length,
                            itemBuilder: (context, index) {
                              return ListTile(
                                title: Text(checks[index].userName),
                              );
                            },
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    },
  );
}

/// Bejegyzéskártya. A számlálókat a hívó adja át.
class PostCard extends StatelessWidget {
  const PostCard({
    required this.post,
    required this.timeLabel,
    required this.checkCount,
    required this.commentCount,
    required this.checkedByMe,
    required this.canManage,
    required this.checkBusy,
    required this.onToggleCheck,
    required this.onShowChecks,
    required this.onOpen,
    this.onEdit,
    this.onDelete,
    this.maxLines = 8,
    super.key,
  });

  final Post post;
  final String timeLabel;
  final String checkCount;
  final String commentCount;
  final bool checkedByMe;
  final bool canManage;
  final bool checkBusy;
  final VoidCallback? onToggleCheck;
  final VoidCallback onShowChecks;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pinned = post.pinned;
    final textColor = pinned ? AppColors.text : theme.colorScheme.onSurface;
    return Card(
      color: pinned ? AppColors.burgundyLight : theme.colorScheme.surface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.appBarDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onOpen,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AuthorAvatar(
                        name: post.authorName,
                        photoUrl: post.authorPhotoUrl,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.authorName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              timeLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: textColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (pinned)
                        const Icon(
                          Icons.push_pin,
                          color: AppColors.burgundy,
                          semanticLabel: 'Kitűzött',
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.text,
                    maxLines: maxLines,
                    overflow: maxLines == null ? null : TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: checkedByMe ? 'Pipázva' : 'Pipálás',
                  onPressed: checkBusy ? null : onToggleCheck,
                  color: AppColors.accentGreen,
                  icon: Icon(
                    checkedByMe
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                  ),
                ),
                InkWell(
                  onTap: onShowChecks,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    child: Text(
                      checkCount,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.accentGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Hozzászólások',
                  onPressed: onOpen,
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(commentCount, style: theme.textTheme.titleMedium),
                ),
                if (canManage)
                  PopupMenuButton<String>(
                    tooltip: 'Műveletek',
                    onSelected: (value) {
                      if (value == 'edit') onEdit?.call();
                      if (value == 'delete') onDelete?.call();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Szerkesztés')),
                      PopupMenuItem(value: 'delete', child: Text('Törlés')),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Betölti a számlálókat, és összeköti a kártyát a műveletekkel.
class PostTile extends ConsumerStatefulWidget {
  const PostTile({
    required this.post,
    required this.user,
    this.maxLines = 8,
    this.onOpen,
    this.showMenu = true,
    super.key,
  });

  final Post post;
  final AppUser user;
  final int? maxLines;
  final VoidCallback? onOpen;
  final bool showMenu;

  @override
  ConsumerState<PostTile> createState() => _PostTileState();
}

class _PostTileState extends ConsumerState<PostTile> {
  var _checkBusy = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final checks = ref.watch(postCheckCountProvider(post.id));
    final comments = ref.watch(postCommentCountProvider(post.id));
    final mine = ref.watch(myCheckProvider(post.id));
    final checked = mine.asData?.value ?? false;
    return PostCard(
      post: post,
      timeLabel: hungarianRelativeTime(post.createdAt, DateTime.now()),
      checkCount: _countLabel(checks),
      commentCount: _countLabel(comments),
      checkedByMe: checked,
      canManage: widget.showMenu && canManagePost(widget.user, post),
      checkBusy: _checkBusy,
      maxLines: widget.maxLines,
      onToggleCheck: () => _toggle(checked),
      onShowChecks: () =>
          showChecksSheet(context, ref.read(postRepositoryProvider), post.id),
      onOpen: widget.onOpen ?? () => context.push(AppRoutes.feedPost(post.id)),
      onEdit: () => context.push(AppRoutes.editPost(post.id)),
      onDelete: () => deletePostFlow(context, ref, post.id),
    );
  }

  String _countLabel(AsyncValue<int> value) {
    return switch (value) {
      AsyncData(:final value) => '$value',
      AsyncError() => '–',
      _ => '…',
    };
  }

  Future<void> _toggle(bool checked) async {
    setState(() => _checkBusy = true);
    final repository = ref.read(postRepositoryProvider);
    try {
      if (checked) {
        await repository.removeCheck(
          postId: widget.post.id,
          userId: widget.user.id,
        );
      } else {
        await repository.addCheck(
          postId: widget.post.id,
          userId: widget.user.id,
          userName: widget.user.name,
        );
      }
      ref.invalidate(postCheckCountProvider(widget.post.id));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _checkBusy = false);
    }
  }
}
