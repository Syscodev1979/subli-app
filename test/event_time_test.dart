import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/features/feed/domain/event_time.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('hu');
  });

  test('a felirat a napot és az időszakot írja', () {
    final start = DateTime(2026, 10, 25, 18);
    final end = DateTime(2026, 10, 25, 20);

    expect(
      eventWhenLabel(start, end),
      'vasárnap, 2026. október 25. · 18:00–20:00',
    );
    expect(eventWhenLabel(start, null), 'vasárnap, 2026. október 25. · 18:00');
    expect(eventSearchText(start), contains('2026'));
    expect(eventSearchText(start), contains('október'));
  });

  test('a vége nem előzheti meg a kezdést', () {
    final start = DateTime(2026, 10, 25, 18);

    expect(eventEndsBeforeStart(start, null), isFalse);
    expect(eventEndsBeforeStart(start, start), isTrue);
    expect(
      eventEndsBeforeStart(start, start.subtract(const Duration(minutes: 1))),
      isTrue,
    );
    expect(
      eventEndsBeforeStart(start, start.add(const Duration(hours: 1))),
      isFalse,
    );
  });

  test('azonos perc ugyanaz az időpont', () {
    expect(sameEventMinute(null, null), isTrue);
    expect(sameEventMinute(DateTime(2026, 10, 25, 18), null), isFalse);
    expect(
      sameEventMinute(
        DateTime(2026, 10, 25, 18, 1, 10),
        DateTime(2026, 10, 25, 18, 1, 40),
      ),
      isTrue,
    );
    expect(
      sameEventMinute(
        DateTime(2026, 10, 25, 18, 1),
        DateTime(2026, 10, 25, 18, 2),
      ),
      isFalse,
    );
  });
}
