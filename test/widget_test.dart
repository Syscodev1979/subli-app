import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastroyal_karate_app/main.dart';

void main() {
  testWidgets('A hírfolyam fejlécén megjelenik a klub neve', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GastroyalApp()));
    await tester.pumpAndSettle();

    expect(find.text('Gastroyal Karate SE'), findsOneWidget);
    expect(find.byTooltip('Menü'), findsOneWidget);

    final appBarTheme = Theme.of(tester.element(find.byType(AppBar)))
        .appBarTheme;
    expect(appBarTheme.backgroundColor, const Color(0xFFFFFFFF));
    expect(appBarTheme.foregroundColor, const Color(0xFF6B1E2E));
    expect(appBarTheme.elevation, 0);
  });
}
