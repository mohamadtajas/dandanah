import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('mobile Quran asset is byte-identical to the desktop bundle', () async {
    final mobile = await File('assets/data/quran.json').readAsBytes();
    final desktop = await File('../src-tauri/data/quran.json').readAsBytes();
    expect(mobile, desktop);
  });

  test('bundled Quran records the hash of the verbatim Tanzil XML', () async {
    final raw = await File('assets/data/quran.json').readAsString();
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final source = (data['source'] as Map).cast<String, dynamic>();

    final xml = await File('../data/quran-uthmani.xml').readAsString();
    final digest = sha256.convert(utf8.encode(xml)).toString();
    expect(source['textSha256'], digest);

    final metadata = await File('../data/quran-metadata.xml').readAsString();
    final metadataDigest = sha256.convert(utf8.encode(metadata)).toString();
    expect(source['metadataSha256'], metadataDigest);
  });
}
