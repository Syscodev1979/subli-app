import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gastroyal_karate_app/main.dart';

void main() {
  testWidgets('A hírfolyam fejlécén megjelenik a klub neve', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: GastroyalApp()));
    await tester.pumpAndSettle();

    expect(find.text('Gastroyal Karate SE'), findsOneWidget);
    expect(find.byTooltip('Menü'), findsOneWidget);
  });
}
