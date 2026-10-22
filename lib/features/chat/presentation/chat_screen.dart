import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants.dart';
import '../../auth/data/auth_providers.dart';
import '../../auth/domain/auth_session.dart';
import '../../feed/domain/search_keywords.dart';
import '../../feed/presentation/feed_palette.dart';
import '../data/chat_providers.dart';
import '../domain/club_member.dart';
import '../domain/conversation.dart';
import 'chat_time.dart';
import 'conversation_format.dart';
import 'conversation_tile.dart';

/// A beszélgetések listája.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authGateProvider).asData?.value;
    final myId = session is AuthSignedIn ? session.user.id : '';
    final conversations = ref.watch(conversationsProvider);
    final members = ref.watch(membersProvider(''));
    final byId = {
      for (final member in members.asData?.value ?? const <ClubMember>[])
        member.id: member,
    };

    return Scaffold(
      backgroundColor: FeedPalette.background(context),
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Vissza',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.feed);
            }
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Row(
          children: [
            _ChatMark(),
            SizedBox(width: 12),
            Text('Üzenetek'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Új üzenet',
            onPressed: () => context.push(AppRoutes.newMessage),
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Keresés a tagok között…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: FeedPalette.field(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Expanded(
            child: conversations.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => const _Empty(message: 'Az üzenetek most nem tölthetők be.'),
              data: (items) {
                final visible = [
                  for (final item in items)
                    if (_matches(item, myId, byId)) item,
                ];
                if (items.isEmpty) {
                  return _Empty(
                    message:
                        'Még nincs beszélgetésed. Keress egy tagot, és írj neki!',
                    action: 'Új üzenet',
                    onAction: () => context.push(AppRoutes.newMessage),
                  );
                }
                if (visible.isEmpty) {
                  return const _Empty(message: 'Nincs ilyen beszélgetés.');
                }
                return ListView.separated(
                  itemCount: visible.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: FeedPalette.divider(context),
                  ),
                  itemBuilder: (context, index) {
                    final item = visible[index];
                    final people = _people(item, myId, byId);
                    final when = item.lastMessage?.createdAt ?? item.updatedAt;
                    return ConversationTile(
                      title: conversationTitle(item, myId, byId),
                      preview: conversationPreview(item, myId),
                      timeLabel: when.millisecondsSinceEpoch == 0
                          ? ''
                          : chatListTime(when, DateTime.now()),
                      unread: item.isUnreadFor(myId),
                      people: people,
                      onTap: () => context.push(AppRoutes.conversation(item.id)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  bool _matches(
    Conversation conversation,
    String myId,
    Map<String, ClubMember> members,
  ) {
    final query = foldAccents(_query.trim().toLowerCase());
    if (query.isEmpty) return true;
    final names = [
      for (final id in conversation.memberIds)
        if (id != myId) members[id]?.name ?? '',
    ];
    return names.any(
      (name) => foldAccents(name.toLowerCase()).contains(query),
    );
  }

  List<ClubMember> _people(
    Conversation conversation,
    String myId,
    Map<String, ClubMember> members,
  ) {
    final others = [
      for (final id in conversation.memberIds)
        if (id != myId) members[id],
    ].whereType<ClubMember>().toList();
    if (!conversation.isGroup) return others.take(1).toList();
    return others;
  }
}

class _ChatMark extends StatelessWidget {
  const _ChatMark();

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'club-chat',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: Ink(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.gradientStart,
                AppColors.gradientMid,
                AppColors.gradientEnd,
              ],
            ),
          ),
          child: const Icon(Icons.chat_bubble, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message, this.action, this.onAction});

  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 56,
              color: AppColors.burgundy.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: FeedPalette.title(context),
                fontSize: 16,
                height: 1.4,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(action!)),
            ],
          ],
        ),
      ),
    );
  }
}
