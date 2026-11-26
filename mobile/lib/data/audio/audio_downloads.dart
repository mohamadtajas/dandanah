import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart' show ChangeNotifier;
import 'package:path_provider/path_provider.dart';

import '../models/audio.dart';
import '../models/quran.dart';
import 'quran_audio_catalog.dart';

typedef AudioFetch = Future<List<int>> Function(Uri uri);

class AudioDownloadCancelled implements Exception {
  const AudioDownloadCancelled();
}

class DownloadToken {
  bool cancelled = false;

  void cancel() => cancelled = true;
}

/// Files live under `<root>/<reciter>/<surah>/<ayah>.mp3` so a completed
/// reciter folder is a complete local copy of the Quran.
class AudioDownloadStore {
  AudioDownloadStore({required this.root, AudioFetch? fetch})
    : _fetch = fetch ?? _httpFetch;

  final Directory root;
  final AudioFetch _fetch;

  static Future<AudioDownloadStore> forApp() async {
    final support = await getApplicationSupportDirectory();
    return AudioDownloadStore(root: Directory('${support.path}/audio'));
  }

  File fileFor(String reciterId, int surah, int ayah) => File(
    '${root.path}/$reciterId/${surah.toString().padLeft(3, '0')}/'
    '${ayah.toString().padLeft(3, '0')}.mp3',
  );

  String? localPath(String reciterId, int surah, int ayah) {
    final file = fileFor(reciterId, surah, ayah);
    return file.existsSync() ? file.uri.toString() : null;
  }

  bool surahDownloaded(String reciterId, int surah, int ayahCount) {
    for (var ayah = 1; ayah <= ayahCount; ayah++) {
      if (!fileFor(reciterId, surah, ayah).existsSync()) return false;
    }
    return true;
  }

  Future<void> downloadTracks(
    List<AudioTrack> tracks, {
    void Function(int done, int total)? onProgress,
    DownloadToken? token,
  }) async {
    final pending = <AudioTrack>[];
    for (final track in tracks) {
      if (!fileFor(track.reciterId, track.surah, track.ayah).existsSync()) {
        pending.add(track);
      }
    }
    var total = tracks.length;
    var done = tracks.length - pending.length;
    onProgress?.call(done, total);

    var next = 0;
    Future<void> worker() async {
      while (true) {
        if (token?.cancelled ?? false) throw const AudioDownloadCancelled();
        final index = next++;
        if (index >= pending.length) return;
        final track = pending[index];
        final file = fileFor(track.reciterId, track.surah, track.ayah);
        await file.parent.create(recursive: true);
        final bytes = await _fetch(Uri.parse(track.url));
        final temp = File('${file.path}.part');
        await temp.writeAsBytes(bytes, flush: true);
        await temp.rename(file.path);
        done++;
        onProgress?.call(done, total);
      }
    }

    try {
      await Future.wait(List.generate(3, (_) => worker()));
    } on AudioDownloadCancelled {
      rethrow;
    }
  }

  int bytesFor(String reciterId) {
    final dir = Directory('${root.path}/$reciterId');
    if (!dir.existsSync()) return 0;
    var total = 0;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is File) total += entity.lengthSync();
    }
    return total;
  }

  void deleteReciter(String reciterId) {
    final dir = Directory('${root.path}/$reciterId');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }

  void deleteSurah(String reciterId, int surah) {
    final dir = Directory(
      '${root.path}/$reciterId/${surah.toString().padLeft(3, '0')}',
    );
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }

  static Future<List<int>> _httpFetch(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('HTTP ${response.statusCode}', uri: uri);
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
      }
      return bytes;
    } finally {
      client.close(force: true);
    }
  }
}

/// Keeps a whole-reciter download running while the user navigates away.
class AudioDownloadManager extends ChangeNotifier {
  AudioDownloadManager(this.store);

  final AudioDownloadStore store;

  bool running = false;
  int done = 0;
  int total = 0;
  String? reciterId;
  String? currentSurah;
  String? error;
  final Set<int> downloadedSurahs = {};
  int bytes = 0;
  DownloadToken? _token;

  bool isDownloaded(int surah) => downloadedSurahs.contains(surah);

  String? localUrlFor(AudioTrack track) =>
      store.localPath(track.reciterId, track.surah, track.ayah);

  AudioTrack localTrack(AudioTrack track) {
    final local = store.localPath(track.reciterId, track.surah, track.ayah);
    return local == null ? track : track.withUrl(local);
  }

  Future<void> refresh(
    AudioReciter reciter,
    List<Surah> surahs, {
    bool replace = false,
  }) async {
    if (surahs.isEmpty) return;
    if (replace) downloadedSurahs.clear();
    for (final surah in surahs) {
      if (store.surahDownloaded(reciter.id, surah.number, surah.ayahCount)) {
        downloadedSurahs.add(surah.number);
      }
    }
    bytes = store.bytesFor(reciter.id);
    notifyListeners();
  }

  Future<void> downloadAll(AudioReciter reciter, List<Surah> surahs) =>
      _run(reciter, surahs, onlySurah: null);

  Future<void> downloadSurah(AudioReciter reciter, Surah surah) =>
      _run(reciter, [surah], onlySurah: surah.number);

  Future<void> _run(
    AudioReciter reciter,
    List<Surah> surahs, {
    required int? onlySurah,
  }) async {
    if (running) return;
    final tracks = <AudioTrack>[
      for (final surah in surahs)
        ...QuranAudioCatalog.surahQueue(
          reciter: reciter,
          surah: surah.number,
          surahName: surah.name,
          ayahCount: surah.ayahCount,
        ),
    ];
    if (tracks.isEmpty) return;

    _token = DownloadToken();
    running = true;
    error = null;
    reciterId = reciter.id;
    currentSurah = onlySurah?.toString();
    done = 0;
    total = tracks.length;
    notifyListeners();

    try {
      await store.downloadTracks(
        tracks,
        token: _token,
        onProgress: (completed, count) {
          done = completed;
          total = count;
          notifyListeners();
        },
      );
    } on AudioDownloadCancelled {
      // Cancelling leaves completed files in place for a later resume.
    } catch (_) {
      error = 'downloadFailed';
    } finally {
      running = false;
      currentSurah = null;
      _token = null;
      await refresh(reciter, surahs);
    }
  }

  void cancel() {
    _token?.cancel();
    error = 'cancelled';
    notifyListeners();
  }
}
