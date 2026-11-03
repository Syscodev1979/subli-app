import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/core/utils/given_name.dart';

void main() {
  test('a vezetéknév utáni első szó a keresztnév', () {
    expect(givenName('Kovács Anna'), 'Anna');
    expect(givenName('Sárosi György'), 'György');
    expect(givenName('Kovács Anna Mária'), 'Anna');
  });

  test('az előtagok kimaradnak', () {
    expect(givenName('Dr. Kovács Anna Mária'), 'Anna');
    expect(givenName('dr. Kovács Anna'), 'Anna');
    expect(givenName('Ifj. Kovács Anna'), 'Anna');
    expect(givenName('id. Kovács Anna'), 'Anna');
    expect(givenName('Prof. Kovács Anna Mária'), 'Anna');
    expect(givenName('Dr. Ifj. Kovács Anna'), 'Anna');
  });

  test('egyszavas név és üres szöveg', () {
    expect(givenName('Anna'), 'Anna');
    expect(givenName('Dr. Anna'), 'Anna');
    expect(givenName('  '), '');
  });
}
