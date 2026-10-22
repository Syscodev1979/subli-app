/// Egy beszélgetés a `conversations` gyűjteményben.
class Conversation {
  const Conversation({
    required this.id,
    required this.memberIds,
    required this.type,
    required this.updatedAt,
    required this.lastMessage,
    required this.lastReadAt,
    required this.hasMinor,
    required this.guardianIds,
  });

  final String id;
  final List<String> memberIds;
  final ConversationType type;
  final DateTime updatedAt;
  final LastMessage? lastMessage;
  final Map<String, DateTime> lastReadAt;
  final bool hasMinor;
  final List<String> guardianIds;

  bool get isGroup => type == ConversationType.group;

  bool isUnreadFor(String uid) {
    final last = lastMessage;
    if (last == null || last.senderId == uid || last.text.isEmpty) return false;
    final readAt = lastReadAt[uid];
    if (readAt == null) return true;
    return last.createdAt.isAfter(readAt);
  }
}

enum ConversationType { direct, group }

class LastMessage {
  const LastMessage({
    required this.text,
    required this.senderId,
    required this.createdAt,
  });

  final String text;
  final String senderId;
  final DateTime createdAt;
}
