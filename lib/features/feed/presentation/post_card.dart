import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../../core/utils/hungarian_relative_time.dart';
import '../../auth/domain/app_user.dart';
import '../data/feed_providers.dart';
import '../domain/post.dart';
import '../domain/post_access.dart';
import '../domain/post_repository.dart';
import 'author_avatar.dart';
import 'feed_controller.dart';
import 'feed_error_message.dart';
import 'feed_palette.dart';
import 'link_text.dart';
import 'post_media_gallery.dart';

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
    message: 'A bejegyzés, a pipák, a hozzászólások és a feltöltött fájlok véglegesen törlődnek.',
  );
  if (!confirmed || !context.mounted) return false;
  try {
    await ref.read(postRepositoryProvider).deletePost(postId);
    await ref.read(feedControllerProvider.notifier).refresh();
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(feedErrorMessage(error, saving: true))),
      );
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
                    child: Text(
                      feedErrorMessage(snapshot.error!, saving: false),
                    ),
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

/// Teljes szélességű bejegyzéskártya.
class PostCard extends StatelessWidget {
  const PostCard({
    required this.post,
    required this.timeLabel,
    required this.checkCount,
    required this.commentCount,
    required this.checkedByMe,
    required this.canManage,
    required this.recentComments,
    required this.onToggleCheck,
    required this.onShowChecks,
    required this.onOpenComments,
    this.onEdit,
    this.onDelete,
    this.expanded = false,
    this.showPreview = true,
    super.key,
  });

  final Post post;
  final String timeLabel;
  final int? checkCount;
  final int? commentCount;
  final bool checkedByMe;
  final bool canManage;
  final List<PostComment> recentComments;
  final VoidCallback? onToggleCheck;
  final VoidCallback onShowChecks;
  final VoidCallback onOpenComments;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool expanded;
  final bool showPreview;

  @override
  Widget build(BuildContext context) {
    final checks = checkCount ?? 0;
    final comments = commentCount ?? 0;
    final showSummary =
        checkCount != null && checks > 0 ||
        commentCount != null && comments > 0;
    final textColor = FeedPalette.title(context);
    return ColoredBox(
      color: FeedPalette.card(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 4, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AuthorAvatar(
                  name: post.authorName,
                  photoUrl: post.authorPhotoUrl,
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                timeLabel,
                                style: TextStyle(
                                  color: FeedPalette.muted(context),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            if (post.pinned) ...[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.push_pin,
                                size: 14,
                                color: FeedPalette.muted(context),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Kitűzve',
                                style: TextStyle(
                                  color: FeedPalette.muted(context),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (canManage)
                  PopupMenuButton<String>(
                    tooltip: 'Műveletek',
                    icon: Icon(
                      Icons.more_horiz,
                      color: FeedPalette.muted(context),
                    ),
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
          if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: _PostBody(
                text: post.text,
                color: textColor,
                expanded: expanded,
              ),
            ),
          if (post.media.isNotEmpty) PostMediaGallery(media: post.media),
          if (showSummary)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  if (checkCount != null && checks > 0)
                    InkWell(
                      onTap: onShowChecks,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: AppColors.accentGreen,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 12,
                                color: AppColors.onPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$checks',
                              style: TextStyle(
                                color: FeedPalette.muted(context),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (commentCount != null && comments > 0)
                    InkWell(
                      onTap: onOpenComments,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '$comments hozzászólás',
                          style: TextStyle(
                            color: FeedPalette.muted(context),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Divider(height: 1, thickness: 1, color: FeedPalette.divider(context)),
          Row(
            children: [
              Expanded(
                child: _CheckButton(
                  checked: checkedByMe,
                  onPressed: onToggleCheck,
                ),
              ),
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_bubble_outline,
                  label: 'Hozzászólás',
                  onPressed: onOpenComments,
                ),
              ),
            ],
          ),
          if (showPreview && recentComments.isNotEmpty) ...[
            Divider(
              height: 1,
              thickness: 1,
              color: FeedPalette.divider(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final comment in recentComments)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AuthorAvatar(
                            name: comment.authorName,
                            photoUrl: comment.authorPhotoUrl,
                            radius: 14,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: comment.authorName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const TextSpan(text: '  '),
                                  TextSpan(text: comment.text),
                                ],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  TextButton(
                    onPressed: onOpenComments,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: FeedPalette.muted(context),
                    ),
                    child: const Text('Az összes hozzászólás megtekintése'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PostBody extends StatefulWidget {
  const _PostBody({
    required this.text,
    required this.color,
    required this.expanded,
  });

  final String text;
  final Color color;
  final bool expanded;

  @override
  State<_PostBody> createState() => _PostBodyState();
}

class _PostBodyState extends State<_PostBody> {
  var _opened = false;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: widget.color, fontSize: 15, height: 1.4);
    if (widget.expanded || _opened) {
      return LinkText(text: widget.text, style: style);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: 6,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinkText(
              text: widget.text,
              style: style,
              maxLines: overflows ? 6 : null,
            ),
            if (overflows)
              GestureDetector(
                onTap: () => setState(() => _opened = true),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '... Továbbiak',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CheckButton extends StatefulWidget {
  const _CheckButton({required this.checked, required this.onPressed});

  final bool checked;
  final VoidCallback? onPressed;

  @override
  State<_CheckButton> createState() => _CheckButtonState();
}

class _CheckButtonState extends State<_CheckButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.28,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.28,
          end: 1,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(_CheckButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.checked && widget.checked) {
      _controller.forward(from: 0);
      HapticFeedback.lightImpact();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.checked
        ? AppColors.accentGreen
        : FeedPalette.muted(context);
    return _ActionButton(
      icon: widget.checked ? Icons.check_circle : Icons.check_circle_outline,
      label: 'Pipa',
      color: color,
      scale: _scale,
      onPressed: widget.onPressed,
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color,
    this.scale,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Animation<double>? scale;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? FeedPalette.muted(context);
    final iconWidget = Icon(icon, color: tint, size: 22);
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (scale == null)
              iconWidget
            else
              ScaleTransition(scale: scale!, child: iconWidget),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: tint,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Betölti a számlálókat, és összeköti a kártyát a műveletekkel.
class PostTile extends ConsumerStatefulWidget {
  const PostTile({
    required this.post,
    required this.user,
    this.expanded = false,
    this.showPreview = true,
    this.onOpenComments,
    super.key,
  });

  final Post post;
  final AppUser user;
  final bool expanded;
  final bool showPreview;
  final VoidCallback? onOpenComments;

  @override
  ConsumerState<PostTile> createState() => _PostTileState();
}

class _PostTileState extends ConsumerState<PostTile> {
  bool? _checkedOverride;
  int? _countOverride;
  var _pending = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final checks = ref.watch(postCheckCountProvider(post.id));
    final comments = ref.watch(postCommentCountProvider(post.id));
    final mine = ref.watch(myCheckProvider(post.id));
    final recent = ref.watch(recentCommentsProvider(post.id));
    final serverChecked = mine.asData?.value ?? false;
    final checked = _checkedOverride ?? serverChecked;
    final serverCount = checks.asData?.value;
    final commentCount = comments.asData?.value;

    ref.listen(myCheckProvider(post.id), (previous, next) {
      final value = next.asData?.value;
      if (_checkedOverride != null && value == _checkedOverride && mounted) {
        setState(() => _checkedOverride = null);
      }
    });
    ref.listen(postCheckCountProvider(post.id), (previous, next) {
      final value = next.asData?.value;
      if (_countOverride != null && value == _countOverride && mounted) {
        setState(() => _countOverride = null);
      }
    });

    return PostCard(
      post: post,
      timeLabel: hungarianRelativeTime(post.createdAt, DateTime.now()),
      checkCount: _countOverride ?? serverCount,
      commentCount: commentCount,
      checkedByMe: checked,
      canManage: canManagePost(widget.user, post),
      recentComments: (commentCount ?? 0) > 0
          ? (recent.asData?.value ?? const <PostComment>[])
          : const <PostComment>[],
      expanded: widget.expanded,
      showPreview: widget.showPreview,
      onToggleCheck: () => _toggle(checked, serverCount),
      onShowChecks: () =>
          showChecksSheet(context, ref.read(postRepositoryProvider), post.id),
      onOpenComments:
          widget.onOpenComments ??
          () => context.push(AppRoutes.feedPost(post.id)),
      onEdit: () => context.push(AppRoutes.editPost(post.id)),
      onDelete: () => deletePostFlow(context, ref, post.id),
    );
  }

  Future<void> _toggle(bool checked, int? serverCount) async {
    if (_pending) return;
    final next = !checked;
    setState(() {
      _pending = true;
      _checkedOverride = next;
      if (serverCount != null) {
        _countOverride = (serverCount + (next ? 1 : -1)).clamp(0, 1 << 20);
      }
    });
    final repository = ref.read(postRepositoryProvider);
    try {
      if (next) {
        await repository.addCheck(
          postId: widget.post.id,
          userId: widget.user.id,
          userName: widget.user.name,
        );
      } else {
        await repository.removeCheck(
          postId: widget.post.id,
          userId: widget.user.id,
        );
      }
      ref.invalidate(postCheckCountProvider(widget.post.id));
    } catch (error) {
      if (mounted) {
        setState(() {
          _checkedOverride = null;
          _countOverride = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(feedErrorMessage(error, saving: true))),
        );
      }
    } finally {
      if (mounted) setState(() => _pending = false);
    }
  }
}
