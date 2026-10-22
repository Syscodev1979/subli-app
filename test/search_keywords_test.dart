import 'package:flutter_test/flutter_test.dart';
import 'package:gastroyal_karate_app/features/feed/domain/search_keywords.dart';

void main() {
  test('a keresőszavak kisbetűsek, ékezet nélkül, egyediek', () {
    expect(searchKeywords('Holnap közös edzés! Edzés és a torna.'), [
      'holnap',
      'kozos',
      'edzes',
      'torna',
    ]);
    expect(searchKeywords(''), isEmpty);
    expect(searchKeywords('a az és'), isEmpty);
    expect(searchKeywords('Őrület 2026'), ['orulet', '2026']);
  });

  test('legfeljebb 200 szó, a rövid szavak kimaradnak', () {
    final text = List.generate(210, (index) => 'szo$index').join(' ');
    expect(searchKeywords(text), hasLength(200));
    expect(searchKeywords('a b cd ef'), ['cd', 'ef']);
  });

  test('a további keresőszavak a szövegben kellenek', () {
    expect(matchesExtraTerms('Holnap edzés', searchTerms('holnap')), isTrue);
    expect(
      matchesExtraTerms('Holnap közös edzés', searchTerms('holnap torna')),
      isFalse,
    );
    expect(
      matchesExtraTerms('Holnap közös edzés', searchTerms('és holnap edzés')),
      isTrue,
    );
  });

  test('a kiemelés ékezetfüggetlen és nem lóg össze', () {
    expect(highlightRanges('Holnap Edzés', ['edzes']), [(start: 7, end: 12)]);
    expect(highlightRanges('aaa', ['a', 'aa']), [(start: 0, end: 3)]);
  });
}
