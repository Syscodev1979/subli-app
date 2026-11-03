import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/hungarian_relative_time.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/domain/auth_session.dart';
import '../../safety/data/safety_repository.dart';
import '../../safety/domain/content_report.dart';
import '../../safety/presentation/report_sheet.dart';
import '../data/feed_providers.dart';
import '../domain/post.dart';
import '../domain/post_access.dart';
import '../../profile/presentation/profile_navigation.dart';
import 'author_avatar.dart';
import 'feed_error_message.dart';
import 'feed_palette.dart';
import 'feed_skeleton.dart';
import 'link_text.dart';
import 'post_card.dart';
import '../../../core/widgets/error_notice.dart';

/// Egy bejegyzés teljes szövege és a hozzászólásai.
class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({required this.postId, super.key});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  final _commentFocus = FocusNode();
  var _sending = false;
  var _scrollAfterSend = false;

  @override
  void initState() {
    super.initState();
    _commentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authGateProvider).asData?.value;
    final user = session is AuthSignedIn ? session.user : null;
    final post = ref.watch(postProvider(widget.postId));
    final comments = ref.watch(postCommentsProvider(widget.postId));
    final canSend = _commentController.text.trim().isNotEmpty && !_sending;

    ref.listen(postCommentsProvider(widget.postId), (previous, next) {
      if (!_scrollAfterSend) return;
      final before = previous?.asData?.value.length ?? 0;
      final after = next.asData?.value.length ?? 0;
      if (after > before) {
        _scrollAfterSend = false;
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToEnd());
      }
    });

    return Scaffold(
      backgroundColor: FeedPalette.background(context),
      appBar: AppBar(title: const Text('Bejegyzés')),
      body: Column(
        children: [
          Expanded(
            child: post.when(
              loading: () => const FeedSkeleton(),
              error: (error, _) => Center(
                child: ErrorNotice(
                  feedErrorMessage(error, saving: false),
                  centered: true,
                ),
              ),
              data: (value) {
                if (value == null) {
                  return const Center(
                    child: Text('A bejegyzés már nem elérhető.'),
                  );
                }
                return comments.when(
                  loading: () => const FeedSkeleton(cards: 1),
                  error: (error, _) => Center(
                    child: ErrorNotice(
                      feedErrorMessage(error, saving: false),
                      centered: true,
                    ),
                  ),
                  data: (items) => ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(bottom: 16),
                    children: [
                      if (user != null)
                        PostTile(
                          post: value,
                          user: user,
                          expanded: true,
                          showPreview: false,
                          onOpenComments: _commentFocus.requestFocus,
                        ),
                      const SizedBox(height: 8),
                      if (items.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'Még nincs hozzászólás.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: FeedPalette.muted(context)),
                          ),
                        )
                      else
                        for (final comment in items)
                          if (!comment.hidden &&
                              !(ref.watch(blockedIdsProvider).asData?.value ??
                                      const <String>{})
                                  .contains(comment.authorId))
                            _CommentBubble(
                              comment: comment,
                              canDelete:
                                  user != null &&
                                  canDeleteComment(user, comment),
                              canReport:
                                  user != null && comment.authorId != user.id,
                              onDelete: () => _deleteComment(comment.id),
                              onReport: () => showReportSheet(
                                context,
                                ref,
                                targetType: ReportTargetType.comment,
                                targetId: comment.id,
                                targetAuthorId: comment.authorId,
                                targetPath:
                                    'posts/${value.id}/comments/${comment.id}',
                                snapshot: comment.text,
                              ),
                            ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (user != null)
            Material(
              color: FeedPalette.card(context),
              elevation: 8,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AuthorAvatar(
                        name: user.name,
                        photoUrl: user.photoUrl,
                        radius: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _commentFocus,
                          maxLength: PostLimits.commentText,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          style: TextStyle(color: FeedPalette.title(context)),
                          decoration: InputDecoration(
                            hintText: 'Írj hozzászólást...',
                            counterText: '',
                            filled: true,
                            fillColor: FeedPalette.field(context),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(24),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onSubmitted: canSend ? (_) => _send(user) : null,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Küldés',
                        onPressed: canSend ? () => _send(user) : null,
                        icon: Icon(
                          Icons.send,
                          color: canSend
                              ? Theme.of(context).colorScheme.primary
                              : FeedPalette.muted(context),
                        ),
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

  void _scrollToEnd() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
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
      _scrollAfterSend = true;
      ref.invalidate(postCommentCountProvider(widget.postId));
      ref.invalidate(recentCommentsProvider(widget.postId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(errorSnackBar(feedErrorMessage(error, saving: true)));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await ref
          .read(postRepositoryProvider)
          .deleteComment(postId: widget.postId, commentId: commentId);
      ref.invalidate(postCommentCountProvider(widget.postId));
      ref.invalidate(recentCommentsProvider(widget.postId));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(errorSnackBar(feedErrorMessage(error, saving: true)));
      }
    }
  }

  String? _photo(String? photoUrl) {
    final value = photoUrl?.trim();
    if (value == null || value.isEmpty) return null;
    return value;
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({
    required this.comment,
    required this.canDelete,
    required this.canReport,
    required this.onDelete,
    required this.onReport,
  });

  final PostComment comment;
  final bool canDelete;
  final bool canReport;
  final VoidCallback onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: FeedPalette.field(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileTap(
            userId: comment.authorId,
            child: Text(
              comment.authorName,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: FeedPalette.title(context),
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 2),
          LinkText(
            text: comment.text,
            style: TextStyle(
              color: FeedPalette.title(context),
              fontSize: 15,
              height: 1.35,
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileTap(
            userId: comment.authorId,
            child: AuthorAvatar(
              name: comment.authorName,
              photoUrl: comment.authorPhotoUrl,
              radius: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPress: canDelete || canReport
                      ? () => _ask(context)
                      : null,
                  child: bubble,
                ),
                const SizedBox(height: 4),
                Text(
                  hungarianRelativeTime(comment.createdAt, DateTime.now()),
                  style: TextStyle(
                    color: FeedPalette.muted(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _ask(BuildContext context) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canReport)
                ListTile(
                  leading: const Icon(Icons.flag_outlined),
                  title: const Text('Jelentés'),
                  onTap: () => Navigator.of(context).pop('report'),
                ),
              if (canDelete)
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Törlés'),
                  onTap: () => Navigator.of(context).pop('delete'),
                ),
            ],
          ),
        );
      },
    );
    if (action == 'delete') onDelete();
    if (action == 'report') onReport();
  }
}
