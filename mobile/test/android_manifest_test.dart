import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the release manifest can reach EveryAyah', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    // Debug/profile manifests add INTERNET themselves, which previously hid
    // the fact that release builds could not stream audio.
    expect(manifest, contains('android.permission.INTERNET'));
  });

  test('https links can be opened for source attribution', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();

    expect(manifest, contains('android.intent.action.VIEW'));
    expect(manifest, contains('android:scheme="https"'));
  });
}
