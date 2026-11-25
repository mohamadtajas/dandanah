import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/db/app_database.dart';
import 'package:sakeenah_mobile/data/repositories/quran_reader_repository.dart';
import 'package:sakeenah_mobile/data/settings_store.dart';

void main() {
  late AppDatabase db;
  late QuranReaderRepository reader;

  setUp(() {
    db = AppDatabase.memory();
    reader = DriftQuranReaderRepository(db);
  });

  tearDown(() => db.close());

  test('resume position starts empty and updates in place', () async {
    expect(await reader.position(), isNull);

    await reader.savePosition(2, 255);
    final first = await reader.position();
    expect(first!.surah, 2);
    expect(first.ayah, 255);

    await reader.savePosition(18, 10);
    final second = await reader.position();
    expect(second!.surah, 18);
    expect(second.ayah, 10);
    expect(await db.select(db.readerState).get(), hasLength(1));
  });

  test('bookmark toggles on and off without duplicates', () async {
    expect(await reader.bookmarks(), isEmpty);
    expect(await reader.isBookmarked(2, 255), isFalse);

    await reader.toggleBookmark(2, 255);
    expect(await reader.isBookmarked(2, 255), isTrue);
    expect(await reader.bookmarks(), hasLength(1));

    await reader.toggleBookmark(2, 255);
    expect(await reader.isBookmarked(2, 255), isFalse);
    expect(await reader.bookmarks(), isEmpty);
  });

  test('bookmarks are newest first and removable', () async {
    await reader.toggleBookmark(1, 1);
    await reader.toggleBookmark(18, 10);
    final list = await reader.bookmarks();
    expect(list, hasLength(2));
    expect(list.first.surah, 18);

    await reader.removeBookmark(1, 1);
    expect(await reader.bookmarks(), hasLength(1));
    expect(await reader.isBookmarked(1, 1), isFalse);
  });

  test('font size defaults to 28 and clamps to 20..44', () async {
    expect(await reader.fontSize(), 28);

    await reader.saveFontSize(34);
    expect(await reader.fontSize(), 34);
    expect(
      await SettingsStore.readInt(db, QuranReaderRepository.fontSizeKey),
      34,
    );

    await reader.saveFontSize(5);
    expect(await reader.fontSize(), 20);
    await reader.saveFontSize(99);
    expect(await reader.fontSize(), 44);
  });
}
