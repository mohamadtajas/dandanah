import 'package:material_ui/material_ui.dart';

import '../../data/app_services.dart';
import '../../data/audio/playback_controller.dart';
import '../../data/audio/quran_audio_catalog.dart';
import '../../data/models/audio.dart';
import '../../data/models/quran.dart';
import '../../data/text.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/sakeenah_theme.dart';

class AudioPage extends StatefulWidget {
  const AudioPage({super.key, this.playback});

  final PlaybackController? playback;

  @override
  State<AudioPage> createState() => _AudioPageState();
}

class _AudioPageState extends State<AudioPage> {
  late final AppServices _services = AppServices.current;
  late final PlaybackController _playback =
      widget.playback ?? _services.playback;
  final TextEditingController _search = TextEditingController();
  List<Surah> _surahs = const [];
  AudioReciter _reciter = QuranAudioCatalog.reciters.first;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final surahs = await _services.quran.surahs();
      if (!mounted) return;
      setState(() {
        _surahs = surahs;
        _loading = false;
        _failed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _play(Surah surah) async {
    final queue = QuranAudioCatalog.surahQueue(
      reciter: _reciter,
      surah: surah.number,
      surahName: surah.name,
      ayahCount: surah.ayahCount,
    );
    await _playback.playQueue(queue);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_failed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.audioLoadError),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () {
                setState(() => _loading = true);
                _load();
              },
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final query = normalizeArabic(_search.text);
    final filtered = query.isEmpty
        ? _surahs
        : _surahs
              .where(
                (surah) =>
                    normalizeArabic(surah.name).contains(query) ||
                    normalizeArabic(surah.englishName).contains(query),
              )
              .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: DropdownButtonFormField<AudioReciter>(
            initialValue: _reciter,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.audioChooseReciter),
            items: [
              for (final reciter in QuranAudioCatalog.reciters)
                DropdownMenuItem(
                  value: reciter,
                  child: Text(
                    '${reciter.name} · ${reciter.style}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _reciter = value);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            key: const ValueKey('audio-search'),
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: l10n.audioSearchSurah,
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              suffixIcon: _search.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                    ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final surah = filtered[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 17,
                    backgroundColor: scheme.primary.withValues(alpha: 0.12),
                    child: Text(
                      '${surah.number}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    surah.name,
                    style: SakeenahTheme.quran(
                      Theme.of(context).textTheme.titleMedium!,
                      size: 18,
                    ).copyWith(color: scheme.onSurface),
                  ),
                  subtitle: Text(
                    '${surah.englishName} · ${l10n.quranAyahCount(surah.ayahCount)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  trailing: IconButton(
                    key: ValueKey('audio-play-${surah.number}'),
                    tooltip: l10n.audioPlaySurah,
                    onPressed: () => _play(surah),
                    icon: const Icon(Icons.play_circle_outline_rounded),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
