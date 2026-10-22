import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import '../../auth/domain/auth_session.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../domain/club_member.dart';
import '../domain/conversation.dart';
import 'firestore_chat_repository.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return FirestoreChatRepository(FirebaseFirestore.instance);
});

final conversationsProvider = StreamProvider<List<Conversation>>((ref) {
  final session = ref.watch(authGateProvider).asData?.value;
  if (session is! AuthSignedIn) return Stream.value(const []);
  return ref.watch(chatRepositoryProvider).watchConversations(session.user.id);
});

final unreadConversationCountProvider = Provider<int>((ref) {
  final session = ref.watch(authGateProvider).asData?.value;
  final conversations =
      ref.watch(conversationsProvider).asData?.value ?? const <Conversation>[];
  if (session is! AuthSignedIn) return 0;
  return conversations.where((item) => item.isUnreadFor(session.user.id)).length;
});

final membersProvider = StreamProvider.family<List<ClubMember>, String>((
  ref,
  keyword,
) {
  return ref.watch(chatRepositoryProvider).watchMembers(
    keyword: keyword.isEmpty ? null : keyword,
  );
});

final messagesProvider =
    StreamProvider.family<List<ChatMessage>, ({String id, int limit})>((
      ref,
      query,
    ) {
      return ref.watch(chatRepositoryProvider).watchMessages(
        query.id,
        limit: query.limit,
      );
    });
