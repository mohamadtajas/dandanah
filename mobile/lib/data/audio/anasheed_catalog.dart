import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../models/audio.dart';

class AnasheedException implements Exception {
  const AnasheedException(this.message);

  final String message;
}

class AnasheedTrack {
  const AnasheedTrack({
    required this.id,
    required this.title,
    required this.creator,
    required this.license,
    required this.licenseVersion,
    required this.audioUrl,
    required this.landingUrl,
    required this.source,
    this.duration,
  });

  final String id;
  final String title;
  final String creator;
  final String license;
  final String licenseVersion;
  final String audioUrl;
  final String landingUrl;
  final String source;
  final Duration? duration;

  String get licenseLabel {
    if (license == 'cc0') return 'CC0 1.0';
    return 'CC ${license.toUpperCase()} $licenseVersion';
  }

  AudioTrack toAudioTrack(int index) => AudioTrack(
    id: 'anasheed:$id',
    reciterId: 'anasheed',
    reciterName: creator.isEmpty ? 'أناشيد' : creator,
    surah: 0,
    ayah: index + 1,
    surahName: title,
    url: audioUrl,
  );

  factory AnasheedTrack.fromJson(Map<String, dynamic> json) {
    final audioUrl = (json['url'] as String?)?.trim() ?? '';
    final id = (json['id'] as String?)?.trim() ?? audioUrl;
    final durationMs = (json['duration'] as num?)?.toInt() ?? 0;
    return AnasheedTrack(
      id: id,
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : 'نشيد',
      creator: (json['creator'] as String?)?.trim() ?? '',
      license: (json['license'] as String?)?.trim() ?? 'unknown',
      licenseVersion: (json['license_version'] as String?)?.trim() ?? '',
      audioUrl: audioUrl,
      landingUrl: (json['foreign_landing_url'] as String?)?.trim() ?? '',
      source: (json['source'] as String?)?.trim() ?? '',
      duration: durationMs > 0 ? Duration(milliseconds: durationMs) : null,
    );
  }
}

abstract interface class AnasheedSource {
  Future<List<AnasheedTrack>> search(String query);
}

typedef AnasheedFetch = Future<String> Function(Uri uri);

/// Openverse indexes CC-licensed audio from Wikimedia Commons, Freesound and
/// Jamendo and needs no API key. Only permissive licences are requested.
class OpenverseAnasheedSource implements AnasheedSource {
  const OpenverseAnasheedSource({this.fetch, this.pageSize = 20});

  final AnasheedFetch? fetch;
  final int pageSize;

  static const _host = 'api.openverse.org';

  @override
  Future<List<AnasheedTrack>> search(String query) async {
    final term = query.trim().isEmpty ? 'nasheed' : query.trim();
    final uri = Uri.https(_host, '/v1/audio/', {
      'q': term,
      'license': 'cc0,by,by-sa',
      'page_size': '$pageSize',
      'page': '1',
    });

    final body = await (fetch ?? _httpFetch)(uri);
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const AnasheedException('Unexpected Openverse response');
      }
      final results = decoded['results'];
      if (results is! List) return const [];
      final tracks = <AnasheedTrack>[];
      final seen = <String>{};
      for (final item in results) {
        if (item is! Map<String, dynamic>) continue;
        final track = AnasheedTrack.fromJson(item);
        if (track.audioUrl.isEmpty || !seen.add(track.id)) continue;
        tracks.add(track);
      }
      return tracks;
    } on FormatException {
      throw const AnasheedException('Openverse returned invalid JSON');
    }
  }

  static Future<String> _httpFetch(Uri uri) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(uri);
      request.headers
        ..set(HttpHeaders.userAgentHeader, 'Sakeenah/0.1 (personal app)')
        ..set(HttpHeaders.acceptHeader, 'application/json');
      final response = await request.close().timeout(
        const Duration(seconds: 20),
      );
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        throw AnasheedException('Openverse HTTP ${response.statusCode}');
      }
      return body;
    } on TimeoutException {
      throw const AnasheedException('Openverse timed out');
    } on SocketException {
      throw const AnasheedException('No connection to Openverse');
    } finally {
      client.close(force: true);
    }
  }
}
