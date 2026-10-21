import 'package:flutter_test/flutter_test.dart';
import 'package:gastroyal_karate_app/features/auth/domain/age.dart';

void main() {
  test('a 18. születésnap előtt kiskorú, a napján már nem', () {
    final birthDate = DateTime(2008, 10, 21);

    expect(isUnder18(birthDate, onDate: DateTime(2026, 10, 20)), isTrue);
    expect(isUnder18(birthDate, onDate: DateTime(2026, 10, 21)), isFalse);
  });
}
