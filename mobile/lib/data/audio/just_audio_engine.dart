import 'dart:async';

import 'package:just_audio/just_audio.dart';

import '../models/audio.dart';
import 'audio_engine.dart';

class JustAudioEngine implements AudioEngine {
  JustAudioEngine() {
    _subscriptions = [
      _player.playerStateStream.listen((_) => _emit()),
      _player.positionStream.listen((_) => _emit()),
      _player.durationStream.listen((_) => _emit()),
      _player.speedStream.listen((_) => _emit()),
      _player.currentIndexStream.listen((_) => _emit()),
      _player.errorStream.listen((error) {
        _error = error.message;
        _emit();
      }),
    ];
  }

  final AudioPlayer _player = AudioPlayer();
  final StreamController<AudioEngineState> _states =
      StreamController<AudioEngineState>.broadcast();
  late final List<StreamSubscription<dynamic>> _subscriptions;
  List<AudioTrack> _queue = const [];
  AudioRepeatMode _repeat = AudioRepeatMode.off;
  String? _error;
  AudioEngineState _state = const AudioEngineState();

  @override
  Stream<AudioEngineState> get states => _states.stream;

  @override
  AudioEngineState get current => _state;

  void _emit() {
    if (_states.isClosed) return;
    final processing = _player.processingState;
    _state = _state.copyWith(
      queue: _queue,
      index: _player.currentIndex ?? 0,
      playing: _player.playing,
      buffering:
          processing == ProcessingState.loading ||
          processing == ProcessingState.buffering,
      position: _player.position,
      duration: _player.duration ?? Duration.zero,
      speed: _player.speed,
      repeat: _repeat,
      error: _error,
    );
    _states.add(_state);
  }

  @override
  Future<void> setQueue(List<AudioTrack> tracks, {int initialIndex = 0}) async {
    _queue = List.unmodifiable(tracks);
    _error = null;
    if (tracks.isEmpty) {
      await _player.stop();
      _emit();
      return;
    }
    final sources = [
      for (final track in tracks)
        AudioSource.uri(Uri.parse(track.url), tag: track),
    ];
    await _player.setAudioSources(
      sources,
      initialIndex: initialIndex.clamp(0, sources.length - 1),
    );
    _emit();
  }

  @override
  Future<void> play() async {
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> next() => _player.seekToNext();

  @override
  Future<void> previous() => _player.seekToPrevious();

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> setRepeat(AudioRepeatMode repeat) async {
    _repeat = repeat;
    await _player.setLoopMode(switch (repeat) {
      AudioRepeatMode.off => LoopMode.off,
      AudioRepeatMode.one => LoopMode.one,
      AudioRepeatMode.all => LoopMode.all,
    });
    _emit();
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    await _states.close();
  }
}
