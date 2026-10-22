import 'package:flutter_test/flutter_test.dart';
import 'package:gastroyal_karate_app/core/utils/given_name.dart';

void main() {
  test('magyar névsorrendben az utolsó szó a keresztnév', () {
    expect(givenName('Kovács Anna'), 'Anna');
    expect(givenName('Sárosi György'), 'György');
    expect(givenName('Anna'), 'Anna');
    expect(givenName('  '), '');
  });
}
