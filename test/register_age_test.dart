import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:subli_app/app/club_config.dart';
import 'package:subli_app/features/auth/domain/registration_policy.dart';
import 'package:subli_app/features/auth/presentation/auth_frame.dart';
import 'package:subli_app/features/auth/presentation/register_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('hu');
  });

  tearDown(() => ClubConfig.debugAdultsOnlyOverride = null);

  test('18 év alatt a szabály elutasít, a születésnapon már nem', () {
    final today = DateTime(2026, 11, 3);
    expect(
      adultsOnlyBirthDateError(DateTime(2008, 11, 4), onDate: today),
      adultsOnlyRegistrationMessage,
    );
    expect(
      adultsOnlyBirthDateError(DateTime(2008, 11, 3), onDate: today),
      isNull,
    );
    expect(adultsOnlyBirthDateError(null, onDate: today), isNotNull);
  });

  testWidgets('a Subliban nincs Szülő vagyok, és 18 év alatt nem enged tovább', (
    tester,
  ) async {
    ClubConfig.debugAdultsOnlyOverride = true;
    final under18 = DateTime(DateTime.now().year - 10, 1, 1);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: RegisterScreen(debugBirthDate: under18),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sportoló vagyok'), findsOneWidget);
    expect(find.text('Edző vagyok'), findsOneWidget);
    expect(find.text('Szülő vagyok'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'Teszt Anna');
    await tester.enterText(find.byType(TextFormField).at(1), 'anna@example.com');
    await tester.enterText(find.byType(TextFormField).at(2), 'titok123');
    await tester.enterText(find.byType(TextFormField).at(3), 'titok123');
    final privacy = find.byType(Checkbox);
    await tester.ensureVisible(privacy);
    await tester.tap(privacy);
    await tester.pump();
    final submit = find.widgetWithText(AuthPrimaryButton, 'Regisztráció');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();

    expect(find.text(adultsOnlyRegistrationMessage), findsOneWidget);
  });

  testWidgets('szülős klubban a Szülő vagyok megmarad', (tester) async {
    ClubConfig.debugAdultsOnlyOverride = false;
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: RegisterScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Szülő vagyok'), findsOneWidget);
    expect(find.text('Edző vagyok'), findsOneWidget);
  });
}
