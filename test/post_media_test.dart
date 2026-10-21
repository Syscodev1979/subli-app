import 'package:flutter_test/flutter_test.dart';
import 'package:gastroyal_karate_app/features/feed/data/storage_object_path.dart';
import 'package:gastroyal_karate_app/features/feed/domain/post.dart';

void main() {
  test('a média lista csak ismert képet és videót tart meg', () {
    final media = PostMedia.listFrom([
      {
        'type': 'image',
        'url': 'https://example.com/a.jpg',
        'width': 800,
        'height': 600,
      },
      {'type': 'file', 'url': 'https://example.com/x.bin'},
      'rossz',
      {
        'type': 'video',
        'url': 'https://example.com/a.mp4',
        'thumbUrl': 'https://example.com/t.jpg',
        'durationSec': 12,
      },
    ]);

    expect(media, hasLength(2));
    expect(media.first.type, PostMediaType.image);
    expect(media.last.durationSec, 12);
  });

  test('a storage útvonal a letöltési címből jön', () {
    expect(
      storageObjectPath(
        'https://firebasestorage.googleapis.com/v0/b/gastroyal-karate.firebasestorage.app/o/posts%2Fpost-1%2Fa.jpg?alt=media&token=abc',
      ),
      'posts/post-1/a.jpg',
    );
    expect(storageObjectPath('https://example.com/a.jpg'), isNull);
  });
}
