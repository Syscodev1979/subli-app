enum MessageDelivery { sent, sending, failed }

/// Egy üzenet. A [delivery] csak a még nem mentett, helyi példányon tér el.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    required this.deleted,
    this.hidden = false,
    this.delivery = MessageDelivery.sent,
  });

  final String id;
  final String senderId;
  final String text;
  final DateTime createdAt;
  final bool deleted;
  final bool hidden;
  final MessageDelivery delivery;

  ChatMessage copyWith({
    MessageDelivery? delivery,
    String? text,
    bool? deleted,
    bool? hidden,
  }) {
    return ChatMessage(
      id: id,
      senderId: senderId,
      text: text ?? this.text,
      createdAt: createdAt,
      deleted: deleted ?? this.deleted,
      hidden: hidden ?? this.hidden,
      delivery: delivery ?? this.delivery,
    );
  }
}
