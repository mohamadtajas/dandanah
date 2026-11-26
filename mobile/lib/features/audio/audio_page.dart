import 'package:material_ui/material_ui.dart';

import '../../data/app_services.dart';
import '../../data/audio/audio_downloads.dart';
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
  late final AudioDownloadManager _downloads = _services.downloads;
  final TextEditingController _search = TextEditingController();
  List<Surah> _surahs = const [];
  AudioReciter _reciter = QuranAudioCatalog.reciters.first;
  bool _loading = true;
  bool _failed = false;
  bool _wasDownloading = false;

  @override
  void initState() {
    super.initState();
    _downloads.addListener(_onDownloads);
    _load();
  }

  @override
  void dispose() {
    _downloads.removeListener(_onDownloads);
    _search.dispose();
    super.dispose();
  }

  void _onDownloads() {
    if (!mounted) return;
    final was = _wasDownloading;
    _wasDownloading = _downloads.running;
    setState(() {});
    if (!was || _downloads.running) return;
    final l10n = AppLocalizations.of(context)!;
    final message = switch (_downloads.error) {
      'cancelled' => l10n.audioDownloadStopped,
      null => l10n.audioDownloadComplete,
      _ => l10n.audioDownloadFailed,
    };
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
      await _downloads.refresh(_reciter, surahs, replace: true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _play(Surah surah) async {
    final queue = [
      for (final track in QuranAudioCatalog.surahQueue(
        reciter: _reciter,
        surah: surah.number,
        surahName: surah.name,
        ayahCount: surah.ayahCount,
      ))
        _downloads.localTrack(track),
    ];
    try {
      await _playback.playQueue(queue);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.audioPlaybackError),
        ),
      );
    }
  }

  Future<void> _downloadSurah(Surah surah) async {
    await _downloads.downloadSurah(_reciter, surah);
  }

  void _deleteSurah(Surah surah) {
    _downloads.store.deleteSurah(_reciter.id, surah.number);
    _downloads.refresh(_reciter, _surahs, replace: true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.audioDeleted)),
    );
  }

  String _size(int bytes) {
    if (bytes >= 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (bytes >= 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }

  Widget _downloadAction(
    Surah surah,
    AppLocalizations l10n,
    ColorScheme scheme,
  ) {
    final downloaded = _downloads.isDownloaded(surah.number);
    final working =
        _downloads.running && _downloads.currentSurah == '${surah.number}';
    if (working) {
      return const SizedBox(
        width: 44,
        height: 44,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (downloaded) {
      return IconButton(
        key: ValueKey('audio-downloaded-${surah.number}'),
        tooltip: l10n.audioDeleteDownload,
        onPressed: _downloads.running ? null : () => _deleteSurah(surah),
        icon: Icon(Icons.download_done_rounded, color: scheme.primary),
      );
    }
    return IconButton(
      key: ValueKey('audio-download-${surah.number}'),
      tooltip: l10n.audioDownloadSurah,
      onPressed: _downloads.running ? null : () => _downloadSurah(surah),
      icon: const Icon(Icons.download_rounded),
    );
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
    final allDownloaded =
        _surahs.isNotEmpty &&
        _surahs.every((surah) => _downloads.isDownloaded(surah.number));

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
              if (value == null) return;
              setState(() => _reciter = value);
              _downloads.refresh(value, _surahs, replace: true);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 2,
                children: [
                  Text(
                    l10n.audioStorageUsed(_size(_downloads.bytes)),
                    style: TextStyle(
                      fontSize: 10,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  TextButton.icon(
                    key: const ValueKey('audio-download-all'),
                    onPressed: _downloads.running
                        ? _downloads.cancel
                        : (allDownloaded
                              ? null
                              : () =>
                                    _downloads.downloadAll(_reciter, _surahs)),
                    icon: Icon(
                      _downloads.running
                          ? Icons.stop_rounded
                          : (allDownloaded
                                ? Icons.download_done_rounded
                                : Icons.download_rounded),
                      size: 18,
                    ),
                    label: Text(
                      _downloads.running
                          ? l10n.audioCancelDownloadShort
                          : (allDownloaded
                                ? l10n.audioAllDownloaded
                                : l10n.audioDownloadAll),
                    ),
                  ),
                ],
              ),
              if (_downloads.running) ...[
                LinearProgressIndicator(
                  value: _downloads.total == 0
                      ? null
                      : _downloads.done / _downloads.total,
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.audioDownloadProgress(_downloads.done, _downloads.total),
                  style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
                ),
              ],
            ],
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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _downloadAction(surah, l10n, scheme),
                      IconButton(
                        key: ValueKey('audio-play-${surah.number}'),
                        tooltip: l10n.audioPlaySurah,
                        onPressed: () => _play(surah),
                        icon: const Icon(Icons.play_circle_outline_rounded),
                      ),
                    ],
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
