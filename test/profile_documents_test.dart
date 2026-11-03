import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/app/club_config.dart';
import 'package:subli_app/features/auth/data/auth_providers.dart';
import 'package:subli_app/features/auth/domain/app_user.dart';
import 'package:subli_app/features/auth/domain/auth_session.dart';
import 'package:subli_app/features/auth/domain/user_repository.dart';
import 'package:subli_app/features/auth/domain/user_role.dart';
import 'package:subli_app/features/auth/domain/user_status.dart';
import 'package:subli_app/features/auth/presentation/register_screen.dart';
import 'package:subli_app/features/chat/domain/club_member.dart';
import 'package:subli_app/features/feed/presentation/document_card.dart';
import 'package:subli_app/features/profile/data/member_repository.dart';
import 'package:subli_app/features/profile/presentation/member_profile_screen.dart';
import 'package:subli_app/features/profile/presentation/profile_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('hu');
  });

  testWidgets('a saját profilon látszik a név, a lovas szint és az e-mail', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final users = _FakeUsers();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authGateProvider.overrideWithValue(
            AsyncData(AuthSignedIn(_athlete())),
          ),
          userRepositoryProvider.overrideWithValue(users),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Teszt Sportoló'), findsWidgets);
    expect(find.text('Sportoló'), findsOneWidget);
    expect(find.text('Kezdő'), findsOneWidget);
    expect(find.text('teszt@example.com'), findsOneWidget);
    expect(find.text('Születési dátum'), findsOneWidget);

    await tester.tap(find.text('Szerkesztés').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Új Név');
    await tester.tap(find.text('Mentés'));
    await tester.pumpAndSettle();

    expect(users.savedName, 'Új Név');
    expect(find.text('Profil frissítve'), findsOneWidget);
  });

  testWidgets('más profilján nincs e-mail és születési dátum', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authGateProvider.overrideWithValue(
            AsyncData(AuthSignedIn(_athlete())),
          ),
          memberRepositoryProvider.overrideWithValue(
            _FakeMembers(
              const ClubMember(
                id: 'other',
                name: 'Nagy Béla',
                photoUrl: null,
                role: UserRole.athlete,
                isMinor: false,
                parentIds: [],
                beltRank: 'advanced',
              ),
            ),
          ),
        ],
        child: const MaterialApp(home: MemberProfileScreen(userId: 'other')),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nagy Béla'), findsOneWidget);
    expect(find.text('Sportoló'), findsOneWidget);
    expect(find.text('Haladó'), findsOneWidget);
    expect(find.text('Üzenet küldése'), findsOneWidget);
    expect(find.text('E-mail'), findsNothing);
    expect(find.text('Születési dátum'), findsNothing);
    expect(find.textContaining('@'), findsNothing);
  });

  testWidgets('a regisztráción választható az Edző vagyok', (tester) async {
    ClubConfig.debugAdultsOnlyOverride = false;
    addTearDown(() => ClubConfig.debugAdultsOnlyOverride = null);
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RegisterScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Edző vagyok'), findsOneWidget);
    expect(find.text('Sportoló vagyok'), findsOneWidget);
    expect(find.text('Szülő vagyok'), findsOneWidget);
  });

  testWidgets('a dokumentumkártyán látszik a típus, a név és a méret', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: DocumentCard(
            name: 'nagyon-hosszu-oklevel-neve-2026.pdf',
            sizeBytes: 2516582,
            mimeType: 'application/pdf',
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.picture_as_pdf), findsOneWidget);
    expect(find.text('2,4 MB'), findsOneWidget);
    expect(find.textContaining('…'), findsOneWidget);
    expect(find.textContaining('.pdf'), findsOneWidget);
  });
}

AppUser _athlete() {
  return AppUser(
    id: 'athlete-1',
    name: 'Teszt Sportoló',
    email: 'teszt@example.com',
    role: UserRole.athlete,
    birthDate: DateTime(2012, 3, 4),
    photoUrl: null,
    status: UserStatus.active,
    childIds: const [],
    parentIds: const [],
    childRequests: const [],
    createdAt: DateTime(2026, 1, 1),
    beltRank: 'beginner',
  );
}

class _FakeUsers implements UserRepository {
  String? savedName;

  @override
  Future<void> updateOwnProfile({
    required String userId,
    String? name,
    DateTime? birthDate,
    String? photoUrl,
    bool clearPhoto = false,
  }) async {
    savedName = name;
  }

  @override
  Stream<AppUser?> watchUser(String id) => const Stream.empty();

  @override
  Future<void> createUser(AppUser user) async {}

  @override
  Stream<List<AppUser>> watchByStatus(UserStatus status) =>
      const Stream.empty();

  @override
  Stream<List<AppUser>> watchActiveAthletes() => const Stream.empty();

  @override
  Future<void> approveUser({
    required String userId,
    required UserRole currentRole,
    UserRole? assignedRole,
    List<String> childIds = const [],
  }) async {}

  @override
  Future<void> rejectUser(String userId) async {}

  @override
  Future<void> updatePhotoUrl({
    required String userId,
    required String? photoUrl,
  }) async {}

  @override
  Future<void> setBeltRank({
    required String userId,
    required String? beltRank,
  }) async {}

  @override
  Stream<List<AppUser>> watchAll() => const Stream.empty();

  @override
  Future<void> saveMember({
    required String actorId,
    required AppUser before,
    required String name,
    required UserRole role,
    required UserStatus status,
    required String? beltRank,
    required List<String> groupIds,
    required DateTime? birthDate,
    required List<String> childIds,
    required List<String> parentIds,
  }) async {}
}

class _FakeMembers implements MemberRepository {
  _FakeMembers(this.member);

  final ClubMember member;

  @override
  Stream<ClubMember?> watchMember(String id) => Stream.value(member);
}
