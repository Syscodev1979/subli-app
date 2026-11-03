import '../../../app/club_config.dart';
import '../../../core/utils/given_name.dart';
import '../domain/club_member.dart';
import '../domain/conversation.dart';

/// A lista és a fejléc címe. Csoportnál a többiek keresztnevei.
String conversationTitle(
  Conversation conversation,
  String myId,
  Map<String, ClubMember> members,
) {
  final others = [
    for (final id in conversation.memberIds)
      if (id != myId) members[id],
  ].whereType<ClubMember>().toList();
  if (others.isEmpty) return 'Beszélgetés';
  if (conversation.isGroup) {
    final names = [
      for (final person in others)
        if (givenName(person.name).isNotEmpty) givenName(person.name),
    ];
    return names.isEmpty ? 'Csoport' : names.join(', ');
  }
  return others.first.name;
}

/// Közvetlen beszélgetésnél a másik szerepe, csoportnál a csoport jelzés.
String conversationSubtitle(
  Conversation conversation,
  String myId,
  Map<String, ClubMember> members,
) {
  if (conversation.isGroup) return 'Csoport';
  final other = [
    for (final id in conversation.memberIds)
      if (id != myId) members[id],
  ].whereType<ClubMember>().firstOrNull;
  return other?.roleLabel ?? '';
}

String conversationPreview(Conversation conversation, String myId) {
  final last = conversation.lastMessage;
  if (last == null) return 'Még nincs üzenet';
  if (last.text.isEmpty) return 'Ez az üzenet törölve lett';
  if (last.senderId == myId) return 'Te: ${last.text}';
  return last.text;
}

/// A tájékoztató sáv szövege, ha a beszélgetést szülő is látja.
String? guardianNotice(
  Conversation conversation,
  String myId,
  Map<String, ClubMember> members,
) {
  if (ClubConfig.enforceAdultsOnly) return null;
  final names = [
    for (final id in conversation.guardianIds)
      if (id != myId) members[id]?.name,
  ].whereType<String>().where((name) => name.trim().isNotEmpty).toList();
  if (names.isEmpty) return null;
  final listed = switch (names.length) {
    1 => names.single,
    2 => '${names[0]} és ${names[1]}',
    _ => '${names.sublist(0, names.length - 1).join(', ')} és ${names.last}',
  };
  return '🔒 Ezt a beszélgetést $listed is látja.';
}
