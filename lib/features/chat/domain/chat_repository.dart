import 'chat_message.dart';
import 'club_member.dart';
import 'conversation.dart';

/// A chat Firestore- és Cloud Functions-műveletei.
abstract class ChatRepository {
  Stream<List<Conversation>> watchConversations(String uid);

  /// Üres [keyword] esetén minden aktív tag, egyébként a keresőszóra.
  Stream<List<ClubMember>> watchMembers({String? keyword});

  /// A legújabb [limit] üzenet, időrendben.
  Stream<List<ChatMessage>> watchMessages(
    String conversationId, {
    required int limit,
  });

  String newMessageId(String conversationId);

  Future<String> startConversation(String otherId);

  Future<void> sendMessage({
    required String conversationId,
    required String messageId,
    required String senderId,
    required String text,
  });

  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  });

  Future<void> markRead({required String conversationId, required String uid});

  Future<int> backfillMembers();
}
