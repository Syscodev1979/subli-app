import 'package:gastroyal_karate_app/features/chat/domain/chat_message.dart';
import 'package:gastroyal_karate_app/features/chat/domain/chat_repository.dart';
import 'package:gastroyal_karate_app/features/chat/domain/club_member.dart';
import 'package:gastroyal_karate_app/features/chat/domain/conversation.dart';

/// Üres chat a hírfolyam tesztjeihez, Firebase nélkül.
class FakeChatRepository implements ChatRepository {
  const FakeChatRepository();

  @override
  Stream<List<Conversation>> watchConversations(String uid) {
    return Stream.value(const []);
  }

  @override
  Stream<List<ClubMember>> watchMembers({String? keyword}) {
    return Stream.value(const []);
  }

  @override
  Stream<List<ChatMessage>> watchMessages(
    String conversationId, {
    required int limit,
  }) {
    return Stream.value(const []);
  }

  @override
  String newMessageId(String conversationId) => 'local-message';

  @override
  Future<String> startConversation(String otherId) async => 'conversation-1';

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String messageId,
    required String senderId,
    required String text,
  }) async {}

  @override
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) async {}

  @override
  Future<void> markRead({
    required String conversationId,
    required String uid,
  }) async {}

  @override
  Future<int> backfillMembers() async => 0;
}
