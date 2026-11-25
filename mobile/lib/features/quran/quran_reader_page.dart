import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../data/app_services.dart';
import '../../data/models/quran.dart';
import '../../data/repositories/quran_reader_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/sakeenah_theme.dart';

class QuranReaderPage extends StatefulWidget {
  const QuranReaderPage.surah({
    super.key,
    required int this.surah,
    this.initialAyah,
  }) : juz = null;

  const QuranReaderPage.juz({
    super.key,
    required int this.juz,
    this.initialAyah,
  }) : surah = null;

  final int? surah;
  final int? juz;
  final int? initialAyah;

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  late final AppServices _services = AppServices.current;
  final ItemScrollController _scroll = ItemScrollController();
  final ItemPositionsListener _positions = ItemPositionsListener.create();
  Timer? _saveTimer;
  ({int surah, int ayah})? _pending;
  List<_Entry> _entries = const [];
  Set<String> _bookmarked = {};
  int _fontSize = QuranReaderRepository.defaultFontSize;
  int _initialIndex = 0;
  String _surahTitle = '';
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    _positions.itemPositions.removeListener(_onPositions);
    final pending = _pending;
    if (pending != null) {
      unawaited(
        _services.quranReader
            .savePosition(pending.surah, pending.ayah)
            .catchError((_) {}),
      );
    }
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final quran = _services.quran;
      final size = await _services.quranReader.fontSize();
      final bookmarks = await _services.quranReader.bookmarks();
      final entries = <_Entry>[];
      Surah? header;
      if (widget.surah != null) {
        header = await quran.surahByNumber(widget.surah!);
        final ayahs = await quran.ayahsForSurah(widget.surah!);
        if (header != null) entries.add(_Entry.surah(header));
        entries.addAll(ayahs.map(_Entry.ayah));
      } else {
        final ayahs = await quran.ayahsForJuz(widget.juz!);
        final surahs = {
          for (final surah in await quran.surahs()) surah.number: surah,
        };
        var current = -1;
        for (final ayah in ayahs) {
          if (ayah.surah != current) {
            current = ayah.surah;
            final surah = surahs[ayah.surah];
            if (surah != null) entries.add(_Entry.surah(surah));
          }
          entries.add(_Entry.ayah(ayah));
        }
      }
      var initialIndex = 0;
      final initialAyah = widget.initialAyah;
      if (initialAyah != null) {
        final index = entries.indexWhere(
          (entry) => entry.ayah?.number == initialAyah,
        );
        if (index >= 0) initialIndex = index;
      }
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _bookmarked = {
          for (final bookmark in bookmarks)
            '${bookmark.surah}:${bookmark.ayah}',
        };
        _fontSize = size;
        _initialIndex = initialIndex;
        _surahTitle = header?.name ?? '';
        _loading = false;
        _failed = false;
      });
      _positions.itemPositions.addListener(_onPositions);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _onPositions() {
    final positions = _positions.itemPositions.value;
    if (positions.isEmpty) return;
    final visible =
        positions.where((position) => position.itemTrailingEdge > 0).toList()
          ..sort((a, b) => a.index.compareTo(b.index));
    for (final position in visible) {
      if (position.index < 0 || position.index >= _entries.length) continue;
      final ayah = _entries[position.index].ayah;
      if (ayah != null) {
        _queueSave(ayah);
        return;
      }
    }
  }

  void _queueSave(Ayah ayah) {
    _pending = (surah: ayah.surah, ayah: ayah.number);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), () {
      final pending = _pending;
      if (pending == null) return;
      unawaited(
        _services.quranReader
            .savePosition(pending.surah, pending.ayah)
            .catchError((_) {}),
      );
    });
  }

  void _saveNow(Ayah ayah) {
    _pending = (surah: ayah.surah, ayah: ayah.number);
    _saveTimer?.cancel();
    unawaited(
      _services.quranReader
          .savePosition(ayah.surah, ayah.number)
          .catchError((_) {}),
    );
  }

  Future<void> _toggleBookmark(Ayah ayah) async {
    await _services.quranReader.toggleBookmark(ayah.surah, ayah.number);
    if (!mounted) return;
    final key = '${ayah.surah}:${ayah.number}';
    setState(() {
      if (!_bookmarked.remove(key)) _bookmarked.add(key);
    });
  }

  Future<void> _changeFont(int delta) async {
    final next = (_fontSize + delta).clamp(
      QuranReaderRepository.minFontSize,
      QuranReaderRepository.maxFontSize,
    );
    if (next == _fontSize) return;
    setState(() => _fontSize = next);
    await _services.quranReader.saveFontSize(next);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final title = widget.surah != null
        ? _surahTitle
        : l10n.quranJuz(widget.juz!);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            key: const ValueKey('quran-font-decrease'),
            tooltip: l10n.quranFontDecrease,
            onPressed: _fontSize <= QuranReaderRepository.minFontSize
                ? null
                : () => _changeFont(-2),
            icon: const Icon(Icons.text_decrease_rounded),
          ),
          IconButton(
            key: const ValueKey('quran-font-increase'),
            tooltip: l10n.quranFontIncrease,
            onPressed: _fontSize >= QuranReaderRepository.maxFontSize
                ? null
                : () => _changeFont(2),
            icon: const Icon(Icons.text_increase_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _failed
          ? Center(
              child: Text(
                l10n.quranReaderError,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            )
          : ScrollablePositionedList.builder(
              initialScrollIndex: _initialIndex,
              itemCount: _entries.length,
              itemScrollController: _scroll,
              itemPositionsListener: _positions,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              itemBuilder: (context, index) {
                final entry = _entries[index];
                final surah = entry.surah;
                if (surah != null) {
                  return _SurahHeader(surah: surah);
                }
                final ayah = entry.ayah!;
                return _AyahTile(
                  ayah: ayah,
                  fontSize: _fontSize.toDouble(),
                  bookmarked: _bookmarked.contains(
                    '${ayah.surah}:${ayah.number}',
                  ),
                  onTap: () => _saveNow(ayah),
                  onBookmark: () => _toggleBookmark(ayah),
                );
              },
            ),
    );
  }
}

class _Entry {
  const _Entry.surah(Surah this.surah) : ayah = null;

  const _Entry.ayah(Ayah this.ayah) : surah = null;

  final Surah? surah;
  final Ayah? ayah;
}

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah});

  final Surah surah;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 18, 8, 10),
      child: Column(
        children: [
          Text(
            surah.name,
            textAlign: TextAlign.center,
            style: SakeenahTheme.quran(
              Theme.of(context).textTheme.headlineSmall!,
              size: 30,
            ).copyWith(color: scheme.primary),
          ),
          const SizedBox(height: 4),
          Text(
            '${surah.isMakkan ? l10n.quranMakkah : l10n.quranMadinah} · '
            '${l10n.quranAyahCount(surah.ayahCount)}',
            style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
          ),
          if (surah.bismillah != null) ...[
            const SizedBox(height: 14),
            Text(
              surah.bismillah!,
              textAlign: TextAlign.center,
              style: SakeenahTheme.quran(
                Theme.of(context).textTheme.titleLarge!,
                size: 24,
              ).copyWith(color: scheme.onSurface),
            ),
          ],
          const SizedBox(height: 8),
          Divider(color: scheme.outline),
        ],
      ),
    );
  }
}

class _AyahTile extends StatelessWidget {
  const _AyahTile({
    required this.ayah,
    required this.fontSize,
    required this.bookmarked,
    required this.onTap,
    required this.onBookmark,
  });

  final Ayah ayah;
  final double fontSize;
  final bool bookmarked;
  final VoidCallback onTap;
  final VoidCallback onBookmark;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      key: ValueKey('quran-ayah-${ayah.surah}-${ayah.number}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: scheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    '${ayah.number}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ),
                if (ayah.sajda) ...[
                  const SizedBox(width: 6),
                  Text(
                    l10n.quranSajda,
                    style: TextStyle(fontSize: 9, color: scheme.secondary),
                  ),
                ],
                const Spacer(),
                IconButton(
                  key: ValueKey('quran-bookmark-${ayah.surah}-${ayah.number}'),
                  tooltip: bookmarked
                      ? l10n.quranRemoveBookmark
                      : l10n.quranAddBookmark,
                  visualDensity: VisualDensity.compact,
                  onPressed: onBookmark,
                  icon: Icon(
                    bookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 18,
                    color: bookmarked ? scheme.primary : scheme.outline,
                  ),
                ),
              ],
            ),
            Text(
              ayah.text,
              textDirection: TextDirection.rtl,
              style: SakeenahTheme.quran(
                Theme.of(context).textTheme.bodyLarge!,
                size: fontSize,
              ).copyWith(color: scheme.onSurface),
            ),
          ],
        ),
      ),
    );
  }
}
