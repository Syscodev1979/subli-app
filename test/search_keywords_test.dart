import 'package:flutter_test/flutter_test.dart';
import 'package:subli_app/features/feed/domain/event_time.dart';
import 'package:subli_app/features/feed/domain/post.dart';
import 'package:subli_app/features/feed/domain/search_keywords.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('hu');
  });

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

  test('a dokumentum neve és az esemény napja is keresőszó', () {
    final keywords = postSearchKeywords(
      text: 'Nevezés',
      media: const [
        PostMedia(
          type: PostMediaType.document,
          url: 'https://example.com/oklevel.pdf',
          name: 'oklevel-2026.pdf',
          sizeBytes: 1200,
          mimeType: 'application/pdf',
        ),
      ],
      extra: eventSearchText(DateTime(2026, 10, 25)),
    );

    expect(keywords, containsAll(['nevezes', 'oklevel', '2026', 'oktober']));
    expect(keywords, contains('vasarnap'));
  });

  test('a kiemelés ékezetfüggetlen és nem lóg össze', () {
    expect(highlightRanges('Holnap Edzés', ['edzes']), [(start: 7, end: 12)]);
    expect(highlightRanges('aaa', ['a', 'aa']), [(start: 0, end: 3)]);
  });
}
