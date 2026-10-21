import 'package:flutter_test/flutter_test.dart';
import 'package:gastroyal_karate_app/core/utils/hungarian_relative_time.dart';
import 'package:gastroyal_karate_app/core/utils/name_initials.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('hu');
  });

  test('a relatív idő magyarul jelenik meg', () {
    final now = DateTime(2026, 10, 21, 12);

    expect(
      hungarianRelativeTime(DateTime(2026, 10, 21, 11, 55), now),
      '5 perce',
    );
    expect(
      hungarianRelativeTime(DateTime(2026, 10, 21, 11, 59, 20), now),
      'most',
    );
    expect(hungarianRelativeTime(DateTime(2026, 10, 21, 9), now), '3 órája');
    expect(
      hungarianRelativeTime(DateTime(2026, 10, 20, 18, 30), now),
      'tegnap 18:30',
    );
    expect(
      hungarianRelativeTime(now.add(const Duration(minutes: 5)), now),
      'most',
    );

    final older = hungarianRelativeTime(DateTime(2026, 10, 1, 18, 30), now);
    expect(older.contains('tegnap'), isFalse);
    expect(older.contains('18:30'), isTrue);
  });

  test('a kezdőbetűk a név első és utolsó szavából jönnek', () {
    expect(nameInitials('Kovács Anna'), 'KA');
    expect(nameInitials('anna'), 'A');
    expect(nameInitials('  '), '?');
  });
}
