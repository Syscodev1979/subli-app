import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/features/auth/domain/app_user.dart';
import 'package:subli_app/features/auth/domain/user_role.dart';
import 'package:subli_app/features/auth/domain/user_status.dart';
import 'package:subli_app/features/members/domain/training_group.dart';
import 'package:subli_app/features/members/presentation/member_admin_screen.dart';
import 'package:subli_app/features/members/presentation/members_screen.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('hu');
  });

  testWidgets('a taglista ékezet nélkül szűr, és a státusz chip szűkít', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MembersDirectoryView(
            members: [_user(name: 'Kovács Anna', email: 'anna@example.com')],
            groups: [
              TrainingGroup(
                id: 'g1',
                name: 'Kezdők',
                color: '#2E7D32',
                description: '',
                createdAt: DateTime(2026, 1, 1),
              ),
            ],
            onOpen: (_) {},
            onGroups: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kovács Anna'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'kovacs');
    await tester.pump();
    expect(find.text('Kovács Anna'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.text('Felfüggesztve'));
    await tester.pump();
    expect(find.text('Kovács Anna'), findsNothing);
  });

  testWidgets('az adatlapon nincs Admin szerep, a törlés nevet kér', (
    tester,
  ) async {
    var deleted = false;
    final member = _user(name: 'Nagy Béla', email: 'bela@example.com');
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: MemberAdminView(
            member: member,
            actor: _user(
              id: 'admin',
              name: 'Admin',
              email: 'admin-beallitando@invalid',
              role: UserRole.admin,
            ),
            groups: const [],
            candidates: const [],
            onDelete: () async {
              deleted = true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Adminisztrátor'), findsNothing);
    expect(find.text('Sportoló'), findsWidgets);

    await tester.ensureVisible(find.byKey(const Key('delete-member')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-member')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tovább'));
    await tester.pumpAndSettle();

    final dialogButton = find.byKey(const Key('confirm-delete-member'));
    expect(tester.widget<FilledButton>(dialogButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, 'Nagy Béla');
    await tester.pump();
    await tester.tap(dialogButton);
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
  });
}

AppUser _user({
  String id = 'athlete-1',
  required String name,
  required String email,
  UserRole role = UserRole.athlete,
  UserStatus status = UserStatus.active,
}) {
  return AppUser(
    id: id,
    name: name,
    email: email,
    role: role,
    birthDate: DateTime(2014, 5, 1),
    photoUrl: null,
    status: status,
    childIds: const [],
    parentIds: const [],
    childRequests: const [],
    createdAt: DateTime(2026, 3, 1),
  );
}
