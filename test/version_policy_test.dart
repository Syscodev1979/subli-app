import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/features/app_update/domain/version_policy.dart';
import 'package:subli_app/features/app_update/presentation/version_gate.dart';

void main() {
  test('a minimum alatt kötelező, a legújabb alatt csak jelzés', () {
    expect(
      versionPrompt(current: '0.4.0', minVersion: '0.5.0'),
      VersionPrompt.required,
    );
    expect(
      versionPrompt(
        current: '0.5.0',
        minVersion: '0.5.0',
        latestVersion: '0.6.0',
      ),
      VersionPrompt.optional,
    );
    expect(
      versionPrompt(
        current: '0.5.0+6',
        minVersion: '0.5.0',
        latestVersion: '0.5.0',
      ),
      VersionPrompt.none,
    );
    expect(
      versionPrompt(current: '0.5.0', minVersion: null, latestVersion: null),
      VersionPrompt.none,
    );
  });

  testWidgets('a kötelező frissítés bezárhatatlan, és a Frissítés látszik', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          versionPromptProvider.overrideWith(
            (ref) async => VersionPrompt.required,
          ),
        ],
        child: const MaterialApp(home: VersionGate(child: Text('az app'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Új verzió érhető el. A folytatáshoz frissítsd az alkalmazást.',
      ),
      findsOneWidget,
    );
    expect(find.text('Frissítés'), findsOneWidget);
    expect(find.text('az app'), findsNothing);
  });

  testWidgets('a finom jelzés bezárható', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          versionPromptProvider.overrideWith(
            (ref) async => VersionPrompt.optional,
          ),
        ],
        child: const MaterialApp(home: VersionGate(child: Text('az app'))),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Új verzió érhető el.'), findsOneWidget);
    expect(find.text('az app'), findsOneWidget);
    await tester.tap(find.byTooltip('Bezárás'));
    await tester.pumpAndSettle();
    expect(find.text('Új verzió érhető el.'), findsNothing);
  });
}
