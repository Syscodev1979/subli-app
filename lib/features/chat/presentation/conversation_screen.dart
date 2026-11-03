import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/auth_session.dart';
import '../../auth/domain/user_role.dart';
import '../../feed/presentation/author_avatar.dart';
import '../../feed/presentation/feed_palette.dart';
import '../data/chat_providers.dart';
import '../domain/chat_message.dart';
import '../domain/club_member.dart';
import '../domain/conversation.dart';
import 'chat_time.dart';
import 'conversation_format.dart';
import 'message_bubble.dart';
import 'quick_replies.dart';
import '../../../core/widgets/error_notice.dart';

/// Egy beszélgetés üzenetei.
class ConversationScreen extends ConsumerStatefulWidget {
  const ConversationScreen({required this.conversationId, super.key});

  final String conversationId;

  @override
  ConsumerState<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends ConsumerState<ConversationScreen> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  final _pending = <ChatMessage>[];
  var _limit = 30;
  var _loadingOlder = false;
  var _showNew = false;
  var _canSend = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _input.addListener(() {
      final next = _input.text.trim().isNotEmpty;
      if (next != _canSend) setState(() => _canSend = next);
    });
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    _input.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    if (_scroll.position.pixels <= 80 && _showNew) {
      setState(() => _showNew = false);
    }
    final nearTop =
        _scroll.position.pixels >= _scroll.position.maxScrollExtent - 240;
    if (nearTop && !_loadingOlder) {
      _loadingOlder = true;
      setState(() => _limit += 30);
    }
  }

  bool get _atBottom {
    if (!_scroll.hasClients) return true;
    return _scroll.position.pixels <= 80;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _send(String raw, {String? messageId}) async {
    final text = raw.trim();
    if (text.isEmpty || text.length > 2000) return;
    final session = ref.read(authGateProvider).asData?.value;
    if (session is! AuthSignedIn) return;
    final repo = ref.read(chatRepositoryProvider);
    final id = messageId ?? repo.newMessageId(widget.conversationId);
    final local = ChatMessage(
      id: id,
      senderId: session.user.id,
      text: text,
      createdAt: DateTime.now(),
      deleted: false,
      delivery: MessageDelivery.sending,
    );
    setState(() {
      final index = _pending.indexWhere((item) => item.id == id);
      if (index >= 0) {
        _pending[index] = local;
      } else {
        _pending.add(local);
      }
    });
    if (messageId == null) _input.clear();
    _scrollToBottom();
    try {
      await repo.sendMessage(
        conversationId: widget.conversationId,
        messageId: id,
        senderId: session.user.id,
        text: text,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        final index = _pending.indexWhere((item) => item.id == id);
        if (index >= 0) {
          _pending[index] = local.copyWith(delivery: MessageDelivery.failed);
        }
      });
    }
  }

  Future<void> _delete(ChatMessage message) async {
    if (message.delivery != MessageDelivery.sent) {
      setState(() => _pending.removeWhere((item) => item.id == message.id));
      return;
    }
    try {
      await ref
          .read(chatRepositoryProvider)
          .deleteMessage(
            conversationId: widget.conversationId,
            messageId: message.id,
          );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(errorSnackBar('Az üzenet törlése nem sikerült.'));
    }
  }

  void _ownMenu(ChatMessage message) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Másolás'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  Navigator.pop(sheetContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text('Törlés'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _delete(message);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authGateProvider).asData?.value;
    final myId = session is AuthSignedIn ? session.user.id : '';
    final myRole = session is AuthSignedIn ? session.user.role : null;
    final query = (id: widget.conversationId, limit: _limit);
    final messagesState = ref.watch(messagesProvider(query));
    final conversations =
        ref.watch(conversationsProvider).asData?.value ?? const [];
    final members = {
      for (final member
          in ref.watch(membersProvider('')).asData?.value ??
              const <ClubMember>[])
        member.id: member,
    };
    final conversation = conversations
        .where((item) => item.id == widget.conversationId)
        .firstOrNull;

    ref.listen(messagesProvider(query), (previous, next) {
      final arrived = next.asData?.value;
      if (arrived == null) return;
      _loadingOlder = false;
      if (arrived.length < _limit) _loadingOlder = true;
      final known = {for (final message in arrived) message.id};
      if (_pending.any((item) => known.contains(item.id))) {
        setState(() => _pending.removeWhere((item) => known.contains(item.id)));
      }
      if (arrived.isEmpty) return;
      final newest = arrived.last;
      final previousNewest = previous?.asData?.value.lastOrNull?.id;
      if (previousNewest != null && previousNewest != newest.id) {
        if (_atBottom || newest.senderId == myId) {
          _scrollToBottom();
          setState(() => _showNew = false);
        } else {
          setState(() => _showNew = true);
        }
      }
      if (_atBottom && myId.isNotEmpty) {
        unawaited(
          ref
              .read(chatRepositoryProvider)
              .markRead(conversationId: widget.conversationId, uid: myId)
              .catchError((_) {}),
        );
      }
    });

    final server = messagesState.asData?.value ?? const <ChatMessage>[];
    final knownIds = {for (final message in server) message.id};
    final thread = [
      ...server,
      for (final message in _pending)
        if (!knownIds.contains(message.id)) message,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final notice = conversation == null
        ? null
        : guardianNotice(conversation, myId, members);
    final coachPresent =
        conversation != null &&
        conversation.memberIds.any((id) => members[id]?.role == UserRole.coach);
    final showTemplates = showsQuickReplies(myRole, coachPresent);

    return Scaffold(
      backgroundColor: FeedPalette.background(context),
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Vissza',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.chat);
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: _Header(
          conversation: conversation,
          myId: myId,
          members: members,
        ),
      ),
      body: Column(
        children: [
          if (notice != null) _GuardianBanner(text: notice),
          Expanded(
            child: messagesState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => const Center(
                child: Text('Az üzenetek most nem tölthetők be.'),
              ),
              data: (_) => Stack(
                children: [
                  _Thread(
                    controller: _scroll,
                    messages: thread,
                    myId: myId,
                    conversation: conversation,
                    members: members,
                    onLongPress: _ownMenu,
                    onRetry: (message) =>
                        _send(message.text, messageId: message.id),
                  ),
                  if (_showNew)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: Center(
                        child: FilledButton.tonal(
                          onPressed: () {
                            setState(() => _showNew = false);
                            _scrollToBottom();
                          },
                          child: const Text('Új üzenet ↓'),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (showTemplates)
            QuickReplies(
              onSelected: (text) {
                _input.text = text;
                _input.selection = TextSelection.collapsed(offset: text.length);
              },
            ),
          _Composer(
            controller: _input,
            canSend: _canSend,
            onSend: () => _send(_input.text),
          ),
        ],
      ),
    );
  }
}

/// Sablonok csak sportolónak és szülőnek, edzővel folytatott beszélgetésben.
bool showsQuickReplies(UserRole? role, bool coachPresent) {
  if (!coachPresent) return false;
  return role == UserRole.athlete || role == UserRole.parent;
}

class _Header extends StatelessWidget {
  const _Header({
    required this.conversation,
    required this.myId,
    required this.members,
  });

  final Conversation? conversation;
  final String myId;
  final Map<String, ClubMember> members;

  @override
  Widget build(BuildContext context) {
    final conversation = this.conversation;
    if (conversation == null) return const Text('Beszélgetés');
    final others = [
      for (final id in conversation.memberIds)
        if (id != myId) members[id],
    ].whereType<ClubMember>().toList();
    final group = conversation.isGroup && others.length > 1;
    return Row(
      children: [
        if (others.isNotEmpty)
          _HeaderFaces(people: group ? others : others.take(1).toList()),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                conversationTitle(conversation, myId, members),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                conversationSubtitle(conversation, myId, members),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: FeedPalette.muted(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderFaces extends StatelessWidget {
  const _HeaderFaces({required this.people});

  final List<ClubMember> people;

  @override
  Widget build(BuildContext context) {
    if (people.length <= 1) {
      final person = people.first;
      return AuthorAvatar(
        name: person.name,
        photoUrl: person.photoUrl,
        radius: 18,
      );
    }
    final shown = people.take(3).toList();
    return SizedBox(
      width: 28 + (shown.length - 1) * 12,
      height: 36,
      child: Stack(
        children: [
          for (var index = 0; index < shown.length; index++)
            Positioned(
              left: index * 12,
              top: 2,
              child: AuthorAvatar(
                name: shown[index].name,
                photoUrl: shown[index].photoUrl,
                radius: 14,
              ),
            ),
        ],
      ),
    );
  }
}

class _GuardianBanner extends StatelessWidget {
  const _GuardianBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final dark = FeedPalette.isDark(context);
    return Container(
      width: double.infinity,
      color: dark ? AppColors.goldDarkSurface : AppColors.goldLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: dark ? AppColors.goldDark : const Color(0xFF5C4A12),
          fontSize: 13,
        ),
      ),
    );
  }
}

class _Thread extends StatelessWidget {
  const _Thread({
    required this.controller,
    required this.messages,
    required this.myId,
    required this.conversation,
    required this.members,
    required this.onLongPress,
    required this.onRetry,
  });

  final ScrollController controller;
  final List<ChatMessage> messages;
  final String myId;
  final Conversation? conversation;
  final Map<String, ClubMember> members;
  final ValueChanged<ChatMessage> onLongPress;
  final ValueChanged<ChatMessage> onRetry;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final latestOwn = messages.reversed
        .where(
          (message) =>
              message.senderId == myId &&
              !message.deleted &&
              message.delivery == MessageDelivery.sent,
        )
        .firstOrNull;
    final children = <Widget>[];
    for (var index = messages.length - 1; index >= 0; index--) {
      final message = messages[index];
      final newer = index + 1 < messages.length ? messages[index + 1] : null;
      final older = index > 0 ? messages[index - 1] : null;
      final groupedBelow = newer != null && _sameRun(message, newer);
      final groupedAbove = older != null && _sameRun(message, older);
      final mine = message.senderId == myId;
      final receipt = message.id == latestOwn?.id
          ? _receipt(message, conversation, myId, members)
          : null;
      children.add(
        MessageBubble(
          message: message,
          mine: mine,
          groupedAbove: groupedAbove,
          groupedBelow: groupedBelow,
          timeLabel: groupedBelow ? null : chatClock(message.createdAt),
          author: members[message.senderId],
          receipt: receipt?.label,
          seenBy: receipt?.seenBy ?? const [],
          onLongPress: mine && !message.deleted
              ? () => onLongPress(message)
              : null,
          onRetry: message.delivery == MessageDelivery.failed
              ? () => onRetry(message)
              : null,
        ),
      );
      final dayChanges =
          older == null || !_sameDay(message.createdAt, older.createdAt);
      if (dayChanges) {
        children.add(_DayLabel(chatDayLabel(message.createdAt, now)));
      }
    }
    return ListView(
      controller: controller,
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: children,
    );
  }

  _Receipt? _receipt(
    ChatMessage message,
    Conversation? conversation,
    String myId,
    Map<String, ClubMember> members,
  ) {
    if (conversation == null) return const _Receipt('Elküldve');
    final seen = <ClubMember>[];
    for (final id in conversation.memberIds) {
      if (id == myId) continue;
      final read = conversation.lastReadAt[id];
      if (read != null && !read.isBefore(message.createdAt)) {
        final person = members[id];
        if (person != null) seen.add(person);
      }
    }
    if (seen.isEmpty) return const _Receipt('Elküldve');
    return _Receipt('Látta', seenBy: conversation.isGroup ? seen : const []);
  }
}

class _Receipt {
  const _Receipt(this.label, {this.seenBy = const []});

  final String label;
  final List<ClubMember> seenBy;
}

class _DayLabel extends StatelessWidget {
  const _DayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: FeedPalette.muted(context),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.canSend,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool canSend;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                maxLength: 2000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Írj üzenetet…',
                  counterText: '',
                  filled: true,
                  fillColor: FeedPalette.field(context),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (canSend)
              IconButton(
                tooltip: 'Küldés',
                onPressed: onSend,
                icon: const Icon(Icons.send, color: AppColors.burgundy),
              ),
          ],
        ),
      ),
    );
  }
}

bool _sameRun(ChatMessage a, ChatMessage b) {
  if (a.deleted || b.deleted) return false;
  if (a.senderId != b.senderId) return false;
  return _sameDay(a.createdAt, b.createdAt);
}

bool _sameDay(DateTime a, DateTime b) {
  final left = a.toLocal();
  final right = b.toLocal();
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
