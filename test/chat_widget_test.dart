import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/app/theme.dart';
import 'package:subli_app/features/auth/data/auth_providers.dart';
import 'package:subli_app/features/auth/domain/app_user.dart';
import 'package:subli_app/features/auth/domain/auth_session.dart';
import 'package:subli_app/features/auth/domain/user_role.dart';
import 'package:subli_app/features/auth/domain/user_status.dart';
import 'package:subli_app/features/chat/data/chat_providers.dart';
import 'package:subli_app/features/chat/domain/chat_message.dart';
import 'package:subli_app/features/chat/domain/club_member.dart';
import 'package:subli_app/features/chat/domain/conversation.dart';
import 'package:subli_app/features/chat/presentation/chat_button.dart';
import 'package:subli_app/features/chat/presentation/chat_screen.dart';
import 'package:subli_app/features/chat/presentation/conversation_screen.dart';
import 'package:subli_app/features/chat/presentation/message_bubble.dart';
import 'package:subli_app/features/chat/presentation/quick_replies.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'fake_chat_repository.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('hu');
  });

  testWidgets('a beszélgetéslistán látszik az előnézet és az olvasatlan név', (
    tester,
  ) async {
    final now = DateTime.now();
    final sent = DateTime(now.year, now.month, now.day, 14, 32);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authGateProvider.overrideWithValue(AsyncData(AuthSignedIn(_me()))),
          chatRepositoryProvider.overrideWithValue(_ListRepository(sent: sent)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Üzenetek'), findsOneWidget);
    expect(find.text('Keresés a tagok között…'), findsOneWidget);
    expect(find.text('Kovács Anna'), findsOneWidget);
    expect(find.text('Te: Szia'), findsOneWidget);
    expect(find.text('14:32'), findsOneWidget);
    expect(find.text('Nagy Béla'), findsOneWidget);
    expect(find.text('Ott leszek'), findsOneWidget);

    final unreadName = tester.widget<Text>(find.text('Nagy Béla'));
    expect(unreadName.style?.fontWeight, FontWeight.w800);
    final readName = tester.widget<Text>(find.text('Kovács Anna'));
    expect(readName.style?.fontWeight, FontWeight.w600);
  });

  testWidgets('üres lista barátságos szöveget mutat', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authGateProvider.overrideWithValue(AsyncData(AuthSignedIn(_me()))),
          chatRepositoryProvider.overrideWithValue(const FakeChatRepository()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ChatScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Még nincs beszélgetésed. Keress egy tagot, és írj neki!'),
      findsOneWidget,
    );
    expect(find.text('Új üzenet'), findsWidgets);
  });

  testWidgets('a saját buborék fehér, a törölt üzenet dőlt', (tester) async {
    final mine = ChatMessage(
      id: '1',
      senderId: 'me',
      text: 'Szia edző',
      createdAt: DateTime(2026, 10, 22, 14, 0),
      deleted: false,
    );
    final deleted = ChatMessage(
      id: '2',
      senderId: 'anna',
      text: '',
      createdAt: DateTime(2026, 10, 22, 14, 1),
      deleted: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              MessageBubble(
                message: mine,
                mine: true,
                groupedAbove: false,
                groupedBelow: false,
                timeLabel: '14:00',
                receipt: 'Elküldve',
              ),
              MessageBubble(
                message: deleted,
                mine: false,
                groupedAbove: false,
                groupedBelow: false,
                timeLabel: '14:01',
              ),
            ],
          ),
        ),
      ),
    );

    final own = tester.widget<Text>(find.text('Szia edző'));
    expect(own.style?.color, Colors.white);
    expect(find.text('Elküldve'), findsOneWidget);
    final removed = tester.widget<Text>(find.text('Ez az üzenet törölve lett'));
    expect(removed.style?.fontStyle, FontStyle.italic);
  });

  testWidgets('a sablon koppintásra beíródik, és csak a megfelelő szerepnek jár', (
    tester,
  ) async {
    String? filled;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: QuickReplies(onSelected: (text) => filled = text),
        ),
      ),
    );

    await tester.tap(find.text('Késni fogok'));
    expect(filled, 'Késni fogok');
    expect(find.text('Ma nem tudok jönni'), findsOneWidget);
    expect(showsQuickReplies(UserRole.athlete, true), isTrue);
    expect(showsQuickReplies(UserRole.parent, true), isTrue);
    expect(showsQuickReplies(UserRole.coach, true), isFalse);
    expect(showsQuickReplies(UserRole.admin, true), isFalse);
    expect(showsQuickReplies(UserRole.athlete, false), isFalse);
  });

  testWidgets('az olvasatlan jelvény 9 fölött 9+', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatButton(unread: 12, onPressed: () {}),
        ),
      ),
    );

    expect(find.text('9+'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatButton(unread: 3, onPressed: () {}),
        ),
      ),
    );
    expect(find.text('3'), findsOneWidget);
    expect(find.text('9+'), findsNothing);
  });
}

AppUser _me() {
  return AppUser(
    id: 'me',
    name: 'Teszt Anna',
    email: 'anna@example.com',
    role: UserRole.athlete,
    birthDate: DateTime(2000, 1, 1),
    photoUrl: null,
    status: UserStatus.active,
    childIds: const [],
    parentIds: const [],
    childRequests: const [],
    createdAt: DateTime(2026, 1, 1),
  );
}

class _ListRepository extends FakeChatRepository {
  _ListRepository({required this.sent});

  final DateTime sent;

  @override
  Stream<List<Conversation>> watchConversations(String uid) {
    return Stream.value([
      Conversation(
        id: 'with-anna',
        memberIds: const ['me', 'anna'],
        type: ConversationType.direct,
        updatedAt: sent,
        lastMessage: LastMessage(text: 'Szia', senderId: 'me', createdAt: sent),
        lastReadAt: {'me': sent},
        hasMinor: false,
        guardianIds: const [],
      ),
      Conversation(
        id: 'with-bela',
        memberIds: const ['me', 'bela'],
        type: ConversationType.direct,
        updatedAt: sent.subtract(const Duration(minutes: 5)),
        lastMessage: LastMessage(
          text: 'Ott leszek',
          senderId: 'bela',
          createdAt: sent.subtract(const Duration(minutes: 5)),
        ),
        lastReadAt: const {},
        hasMinor: false,
        guardianIds: const [],
      ),
    ]);
  }

  @override
  Stream<List<ClubMember>> watchMembers({String? keyword}) {
    return Stream.value(const [
      ClubMember(
        id: 'anna',
        name: 'Kovács Anna',
        photoUrl: null,
        role: UserRole.coach,
        isMinor: false,
        parentIds: [],
      ),
      ClubMember(
        id: 'bela',
        name: 'Nagy Béla',
        photoUrl: null,
        role: UserRole.athlete,
        isMinor: true,
        parentIds: [],
      ),
    ]);
  }
}
