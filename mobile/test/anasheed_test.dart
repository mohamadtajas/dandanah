import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/audio/anasheed_catalog.dart';

void main() {
  test('parses Openverse results and drops unusable entries', () async {
    late Uri requested;
    final source = OpenverseAnasheedSource(
      fetch: (uri) async {
        requested = uri;
        return '''
        {
          "results": [
            {"id": "1", "title": "Nashid One", "creator": "Artist",
             "license": "by", "license_version": "3.0",
             "url": "https://example.test/1.mp3",
             "foreign_landing_url": "https://example.test/1",
             "source": "wikimedia_audio", "duration": 120000},
            {"id": "1", "title": "Duplicate", "url": "https://example.test/dup.mp3"},
            {"id": "2", "title": "Missing audio", "url": ""}
          ]
        }
        ''';
      },
    );

    final results = await source.search('نشيد');

    expect(requested.host, 'api.openverse.org');
    expect(requested.queryParameters['q'], 'نشيد');
    expect(requested.queryParameters['license'], 'cc0,by,by-sa');
    expect(results, hasLength(1));
    expect(results.single.title, 'Nashid One');
    expect(results.single.licenseLabel, 'CC BY 3.0');
    expect(results.single.duration, const Duration(minutes: 2));

    final audio = results.single.toAudioTrack(0);
    expect(audio.surahName, 'Nashid One');
    expect(audio.reciterName, 'Artist');
    expect(audio.url, 'https://example.test/1.mp3');
  });

  test('defaults to a nasheed query and reports failures', () async {
    late Uri requested;
    final source = OpenverseAnasheedSource(
      fetch: (uri) async {
        requested = uri;
        throw const AnasheedException('network');
      },
    );

    await expectLater(source.search('  '), throwsA(isA<AnasheedException>()));
    expect(requested.queryParameters['q'], 'nasheed');
  });

  test('rejects malformed JSON', () async {
    final source = OpenverseAnasheedSource(fetch: (_) async => 'not json');
    await expectLater(
      source.search('nasheed'),
      throwsA(isA<AnasheedException>()),
    );
  });
}
