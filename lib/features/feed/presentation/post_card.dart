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
import '../domain/post_category.dart';
import '../domain/post_repository.dart';
import '../domain/reaction.dart';
import '../../profile/presentation/profile_navigation.dart';
import 'author_avatar.dart';
import 'category_style.dart';
import 'event_when.dart';
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
    message: 'A bejegyzés, a reakciók, a hozzászólások és a feltöltött fájlok véglegesen törlődnek.',
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

/// A reakciók listája.
Future<void> showReactionsSheet(
  BuildContext context,
  PostRepository repository,
  String postId,
) async {
  final future = repository.fetchReactions(postId);
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: SizedBox(
          height: 360,
          child: FutureBuilder<List<PostReaction>>(
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
              final reactions = snapshot.data ?? const <PostReaction>[];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Text(
                      'Reakciók',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Expanded(
                    child: reactions.isEmpty
                        ? const Center(child: Text('Még nincs reakció.'))
                        : ListView.builder(
                            itemCount: reactions.length,
                            itemBuilder: (context, index) {
                              final reaction = reactions[index];
                              final mark =
                                  reaction.type.emoji ?? reaction.type.label;
                              return ListTile(
                                leading: Text(
                                  mark,
                                  style: const TextStyle(fontSize: 18),
                                ),
                                title: Text(reaction.userName),
                                subtitle: Text(reaction.type.label),
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
    required this.reactionCount,
    required this.reactionTypes,
    required this.commentCount,
    required this.myReaction,
    required this.canManage,
    required this.recentComments,
    required this.onToggleLike,
    required this.onPickReaction,
    required this.onShowReactions,
    required this.onOpenComments,
    this.onEdit,
    this.onDelete,
    this.expanded = false,
    this.showPreview = true,
    this.highlights = const [],
    super.key,
  });

  final Post post;
  final String timeLabel;
  final int? reactionCount;
  final List<ReactionType> reactionTypes;
  final int? commentCount;
  final ReactionType? myReaction;
  final bool canManage;
  final List<PostComment> recentComments;
  final VoidCallback? onToggleLike;
  final ValueChanged<ReactionType> onPickReaction;
  final VoidCallback onShowReactions;
  final VoidCallback onOpenComments;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool expanded;
  final bool showPreview;
  final List<String> highlights;

  @override
  Widget build(BuildContext context) {
    final reactions = reactionCount ?? 0;
    final comments = commentCount ?? 0;
    final showSummary =
        (reactionCount != null && reactions > 0) ||
        (commentCount != null && comments > 0);
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
                ProfileTap(
                  userId: post.authorId,
                  child: AuthorAvatar(
                    name: post.authorName,
                    photoUrl: post.authorPhotoUrl,
                    radius: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ProfileTap(
                          userId: post.authorId,
                          child: Text(
                            post.authorName,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                timeLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: FeedPalette.muted(context),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CategoryLabel(category: post.category),
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
          if (post.category == PostCategory.event && post.eventStartsAt != null)
            EventWhenBanner(
              startsAt: post.eventStartsAt!,
              endsAt: post.eventEndsAt,
            ),
          if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: _PostBody(
                text: post.text,
                color: textColor,
                expanded: expanded,
                highlights: highlights,
              ),
            ),
          if (post.media.isNotEmpty) PostMediaGallery(media: post.media),
          if (showSummary)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Row(
                children: [
                  if (reactionCount != null && reactions > 0)
                    InkWell(
                      onTap: onShowReactions,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            for (final type
                                in (reactionTypes.isEmpty
                                        ? const [ReactionType.like]
                                        : reactionTypes)
                                    .take(3))
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: _ReactionGlyph(type: type),
                              ),
                            Text(
                              '$reactions',
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
                child: _ReactionButton(
                  reaction: myReaction,
                  onPressed: onToggleLike,
                  onPick: onPickReaction,
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
                          ProfileTap(
                            userId: comment.authorId,
                            child: AuthorAvatar(
                              name: comment.authorName,
                              photoUrl: comment.authorPhotoUrl,
                              radius: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                children: [
                                  WidgetSpan(
                                    alignment: PlaceholderAlignment.baseline,
                                    baseline: TextBaseline.alphabetic,
                                    child: ProfileTap(
                                      userId: comment.authorId,
                                      child: Text(
                                        comment.authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
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
    required this.highlights,
  });

  final String text;
  final Color color;
  final bool expanded;
  final List<String> highlights;

  @override
  State<_PostBody> createState() => _PostBodyState();
}

class _PostBodyState extends State<_PostBody> {
  var _opened = false;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(color: widget.color, fontSize: 15, height: 1.4);
    if (widget.expanded || _opened) {
      return LinkText(
        text: widget.text,
        style: style,
        highlights: widget.highlights,
      );
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
              highlights: widget.highlights,
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

class _ReactionButton extends StatefulWidget {
  const _ReactionButton({
    required this.reaction,
    required this.onPressed,
    required this.onPick,
  });

  final ReactionType? reaction;
  final VoidCallback? onPressed;
  final ValueChanged<ReactionType> onPick;

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton>
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
  void didUpdateWidget(_ReactionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reaction != widget.reaction && widget.reaction != null) {
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
    final reaction = widget.reaction;
    final color = reaction == null
        ? FeedPalette.muted(context)
        : _reactionColor(reaction);
    return _ActionButton(
      icon: reaction == ReactionType.like
          ? Icons.check_circle
          : Icons.check_circle_outline,
      emoji: reaction?.emoji,
      label: reaction?.label ?? 'Like',
      color: color,
      scale: _scale,
      onPressed: widget.onPressed,
      onLongPress: () => _openPicker(context),
    );
  }

  void _openPicker(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (overlayContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: entry.remove,
                behavior: HitTestBehavior.opaque,
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              top: (origin.dy - 72).clamp(8, origin.dy),
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(28),
                color: FeedPalette.card(overlayContext),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final type in ReactionType.values)
                        IconButton(
                          tooltip: type.label,
                          onPressed: () {
                            entry.remove();
                            widget.onPick(type);
                          },
                          icon: _ReactionGlyph(type: type, size: 28),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
    overlay.insert(entry);
  }
}

class _ReactionGlyph extends StatelessWidget {
  const _ReactionGlyph({required this.type, this.size = 18});

  final ReactionType type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final emoji = type.emoji;
    if (emoji != null) {
      return Text(emoji, style: TextStyle(fontSize: size * 0.9));
    }
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.accentGreen,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check, size: size * 0.66, color: AppColors.onPrimary),
    );
  }
}

Color _reactionColor(ReactionType type) {
  return switch (type) {
    ReactionType.like => AppColors.accentGreen,
    ReactionType.heart => const Color(0xFFC62828),
    ReactionType.haha ||
    ReactionType.wow ||
    ReactionType.sad => const Color(0xFFF9A825),
    ReactionType.osu => AppColors.burgundy,
  };
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.emoji,
    this.color,
    this.scale,
    this.onLongPress,
  });

  final IconData icon;
  final String? emoji;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;
  final Animation<double>? scale;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? FeedPalette.muted(context);
    final mark = emoji == null
        ? Icon(icon, color: tint, size: 22)
        : Text(emoji!, style: const TextStyle(fontSize: 20));
    final scaled = scale == null
        ? mark
        : ScaleTransition(scale: scale!, child: mark);
    return InkWell(
      onTap: onPressed,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            scaled,
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
    this.highlights = const [],
    super.key,
  });

  final Post post;
  final AppUser user;
  final bool expanded;
  final bool showPreview;
  final VoidCallback? onOpenComments;
  final List<String> highlights;

  @override
  ConsumerState<PostTile> createState() => _PostTileState();
}

class _PostTileState extends ConsumerState<PostTile> {
  ReactionType? _reactionOverride;
  var _hasReactionOverride = false;
  int? _countOverride;
  var _pending = false;

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final reactions = ref.watch(postReactionCountProvider(post.id));
    final types = ref.watch(reactionTypesProvider(post.id));
    final comments = ref.watch(postCommentCountProvider(post.id));
    final mine = ref.watch(myReactionProvider(post.id));
    final recent = ref.watch(recentCommentsProvider(post.id));
    final serverReaction = mine.asData?.value;
    final reaction = _hasReactionOverride ? _reactionOverride : serverReaction;
    final serverCount = reactions.asData?.value;
    final commentCount = comments.asData?.value;

    ref.listen(myReactionProvider(post.id), (previous, next) {
      final value = next.asData?.value;
      if (_hasReactionOverride && value == _reactionOverride && mounted) {
        setState(() => _hasReactionOverride = false);
      }
    });
    ref.listen(postReactionCountProvider(post.id), (previous, next) {
      final value = next.asData?.value;
      if (_countOverride != null && value == _countOverride && mounted) {
        setState(() => _countOverride = null);
      }
    });

    return PostCard(
      post: post,
      timeLabel: hungarianRelativeTime(post.createdAt, DateTime.now()),
      reactionCount: _countOverride ?? serverCount,
      reactionTypes: types.asData?.value ?? const <ReactionType>[],
      commentCount: commentCount,
      myReaction: reaction,
      canManage: canManagePost(widget.user, post),
      recentComments: (commentCount ?? 0) > 0
          ? (recent.asData?.value ?? const <PostComment>[])
          : const <PostComment>[],
      expanded: widget.expanded,
      showPreview: widget.showPreview,
      highlights: widget.highlights,
      onToggleLike: () => _apply(
        reaction == ReactionType.like ? null : ReactionType.like,
        reaction,
        serverCount,
      ),
      onPickReaction: (type) =>
          _apply(reaction == type ? null : type, reaction, serverCount),
      onShowReactions: () => showReactionsSheet(
        context,
        ref.read(postRepositoryProvider),
        post.id,
      ),
      onOpenComments:
          widget.onOpenComments ??
          () => context.push(AppRoutes.feedPost(post.id)),
      onEdit: () => context.push(AppRoutes.editPost(post.id)),
      onDelete: () => deletePostFlow(context, ref, post.id),
    );
  }

  Future<void> _apply(
    ReactionType? next,
    ReactionType? current,
    int? serverCount,
  ) async {
    if (_pending) return;
    setState(() {
      _pending = true;
      _hasReactionOverride = true;
      _reactionOverride = next;
      if (serverCount != null) {
        final delta = (next == null ? 0 : 1) - (current == null ? 0 : 1);
        _countOverride = (serverCount + delta).clamp(0, 1 << 20);
      }
    });
    final repository = ref.read(postRepositoryProvider);
    try {
      if (next == null) {
        await repository.removeReaction(
          postId: widget.post.id,
          userId: widget.user.id,
        );
      } else {
        await repository.setReaction(
          postId: widget.post.id,
          userId: widget.user.id,
          userName: widget.user.name,
          type: next,
        );
      }
      ref.invalidate(postReactionCountProvider(widget.post.id));
      ref.invalidate(reactionTypesProvider(widget.post.id));
    } catch (error) {
      if (mounted) {
        setState(() {
          _hasReactionOverride = false;
          _reactionOverride = null;
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
