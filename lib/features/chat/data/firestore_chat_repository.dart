import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../../app/club_config.dart';
import '../../auth/domain/user_role.dart';
import '../domain/chat_message.dart';
import '../domain/chat_repository.dart';
import '../domain/club_member.dart';
import '../domain/conversation.dart';

class FirestoreChatRepository implements ChatRepository {
  FirestoreChatRepository(this._firestore, {FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'europe-west3');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _firestore.collection('conversations');

  CollectionReference<Map<String, dynamic>> get _members =>
      _firestore.collection('members');

  CollectionReference<Map<String, dynamic>> _messages(String conversationId) {
    return _conversations.doc(conversationId).collection('messages');
  }

  @override
  Stream<List<Conversation>> watchConversations(String uid) {
    return _conversations
        .where('memberIds', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => [for (final doc in snapshot.docs) _conversation(doc)],
        );
  }

  @override
  Stream<List<ClubMember>> watchMembers({String? keyword}) {
    Query<Map<String, dynamic>> query = _members.orderBy('name');
    final term = keyword?.trim();
    if (term != null && term.length >= 2) {
      query = _members
          .where('searchKeywords', arrayContains: term)
          .orderBy('name');
    }
    return query.snapshots().map(
      (snapshot) => [for (final doc in snapshot.docs) ?_member(doc)],
    );
  }

  @override
  Stream<List<ChatMessage>> watchMessages(
    String conversationId, {
    required int limit,
  }) {
    return _messages(conversationId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          final messages = [for (final doc in snapshot.docs) _message(doc)];
          return messages.reversed.toList();
        });
  }

  @override
  String newMessageId(String conversationId) =>
      _messages(conversationId).doc().id;

  @override
  Future<String> startConversation(String otherId) async {
    ClubConfig.rejectGroupConversation(2);
    final result = await _functions.httpsCallable('startConversation').call({
      'otherId': otherId,
    });
    final data = result.data;
    if (data is Map && data['conversationId'] is String) {
      return data['conversationId'] as String;
    }
    throw StateError('A beszélgetés azonosítója hiányzik.');
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String messageId,
    required String senderId,
    required String text,
  }) {
    return _messages(conversationId).doc(messageId).set({
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'deleted': false,
    });
  }

  @override
  Future<void> deleteMessage({
    required String conversationId,
    required String messageId,
  }) {
    return _messages(conversationId)
        .doc(messageId)
        .update({'deleted': true, 'text': ''});
  }

  @override
  Future<void> markRead({required String conversationId, required String uid}) {
    return _conversations.doc(conversationId).update({
      'lastReadAt.$uid': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<int> backfillMembers() async {
    final result = await _functions.httpsCallable('backfillMembers').call();
    final data = result.data;
    if (data is Map && data['count'] is int) return data['count'] as int;
    if (data is Map && data['count'] is num) {
      return (data['count'] as num).toInt();
    }
    return 0;
  }

  Conversation _conversation(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Conversation(
      id: doc.id,
      memberIds: _strings(data['memberIds']),
      type: data['type'] == 'group'
          ? ConversationType.group
          : ConversationType.direct,
      updatedAt: _date(data['updatedAt']),
      lastMessage: _lastMessage(data['lastMessage']),
      lastReadAt: _readMap(data['lastReadAt']),
      hasMinor: data['hasMinor'] == true,
      guardianIds: _strings(data['guardianIds']),
    );
  }

  LastMessage? _lastMessage(Object? raw) {
    if (raw is! Map) return null;
    final senderId = raw['senderId'];
    if (senderId is! String || senderId.isEmpty) return null;
    return LastMessage(
      text: raw['text'] is String ? raw['text'] as String : '',
      senderId: senderId,
      createdAt: _date(raw['createdAt']),
    );
  }

  ClubMember? _member(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return null;
    final role = _role(data['role']);
    if (role == null) return null;
    final photo = data['photoUrl'];
    return ClubMember(
      id: doc.id,
      name: data['name'] is String ? data['name'] as String : '',
      photoUrl: photo is String && photo.isNotEmpty ? photo : null,
      role: role,
      isMinor: data['isMinor'] == true,
      parentIds: _strings(data['parentIds']),
      beltRank: data['beltRank'] is String ? data['beltRank'] as String : null,
    );
  }

  ChatMessage _message(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] is String ? data['senderId'] as String : '',
      text: data['text'] is String ? data['text'] as String : '',
      createdAt: _date(data['createdAt']),
      deleted: data['deleted'] == true,
    );
  }

  UserRole? _role(Object? raw) {
    if (raw is! String) return null;
    for (final role in UserRole.values) {
      if (role.value == raw) return role;
    }
    return null;
  }

  List<String> _strings(Object? raw) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is String) item,
    ];
  }

  Map<String, DateTime> _readMap(Object? raw) {
    if (raw is! Map) return const {};
    return {
      for (final entry in raw.entries)
        if (entry.key is String && entry.value is Timestamp)
          entry.key as String: (entry.value as Timestamp).toDate(),
    };
  }

  DateTime _date(Object? value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
