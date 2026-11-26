import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/audio.dart';
import 'audio_engine.dart';

class JustAudioEngine extends BaseAudioHandler
    with SeekHandler
    implements AudioEngine {
  JustAudioEngine() {
    _subscriptions = [
      _player.playerStateStream.listen((_) => _emit()),
      _player.positionStream.listen((_) => _emit()),
      _player.durationStream.listen((_) => _emit()),
      _player.speedStream.listen((_) => _emit()),
      _player.currentIndexStream.listen((_) {
        _error = null;
        _emit();
      }),
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
  String? _mediaTrackId;
  Duration? _mediaDuration;
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
      clearError: _error == null,
    );
    _states.add(_state);
    final track = _state.current;
    if (track != null) {
      final duration = _player.duration;
      if (_mediaTrackId != track.id || _mediaDuration != duration) {
        _mediaTrackId = track.id;
        _mediaDuration = duration;
        mediaItem.add(
          MediaItem(
            id: track.id,
            title: track.surahName,
            artist: track.reciterName,
            album: track.subtitle,
            duration: duration,
          ),
        );
      }
    } else if (_mediaTrackId != null) {
      _mediaTrackId = null;
      _mediaDuration = null;
      mediaItem.add(null);
    }
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [0, 1, 2],
        processingState: switch (_player.processingState) {
          ProcessingState.idle => AudioProcessingState.idle,
          ProcessingState.loading => AudioProcessingState.loading,
          ProcessingState.buffering => AudioProcessingState.buffering,
          ProcessingState.ready => AudioProcessingState.ready,
          ProcessingState.completed => AudioProcessingState.completed,
        },
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  @override
  Future<void> setQueue(List<AudioTrack> tracks, {int initialIndex = 0}) async {
    _queue = List.unmodifiable(tracks);
    _error = null;
    if (tracks.isEmpty) {
      await _player.stop();
      _mediaTrackId = null;
      _mediaDuration = null;
      _emit();
      return;
    }
    final sources = [
      for (final track in tracks)
        AudioSource.uri(Uri.parse(track.url), tag: track),
    ];
    queue.add([
      for (final track in tracks)
        MediaItem(
          id: track.id,
          title: track.surahName,
          artist: track.reciterName,
          album: track.subtitle,
        ),
    ]);
    try {
      await _player.setAudioSources(
        sources,
        initialIndex: initialIndex.clamp(0, sources.length - 1),
      );
    } catch (error) {
      // A failed load must surface in the UI, not as an unhandled error.
      _error = error.toString();
    }
    _emit();
  }

  @override
  Future<void> play() async {
    if (_error != null) {
      _error = null;
      _emit();
    }
    unawaited(
      _player.play().catchError((Object error) {
        _error = error.toString();
        _emit();
      }),
    );
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> next() async {
    _error = null;
    await _player.seekToNext();
    _emit();
  }

  @override
  Future<void> previous() async {
    _error = null;
    await _player.seekToPrevious();
    _emit();
  }

  @override
  Future<void> skipToNext() => next();

  @override
  Future<void> skipToPrevious() => previous();

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
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) {
    return setRepeat(switch (repeatMode) {
      AudioServiceRepeatMode.none => AudioRepeatMode.off,
      AudioServiceRepeatMode.one => AudioRepeatMode.one,
      AudioServiceRepeatMode.all ||
      AudioServiceRepeatMode.group => AudioRepeatMode.all,
    });
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> stopAndClear() async {
    await _player.stop();
    _queue = const [];
    _error = null;
    _mediaTrackId = null;
    _mediaDuration = null;
    queue.add(const []);
    mediaItem.add(null);
    _state = const AudioEngineState(repeat: AudioRepeatMode.off);
    _state = _state.copyWith(repeat: _repeat);
    if (!_states.isClosed) _states.add(_state);
    playbackState.add(
      playbackState.value.copyWith(
        controls: const [],
        playing: false,
        processingState: AudioProcessingState.idle,
      ),
    );
  }

  @override
  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player.dispose();
    await _states.close();
  }
}
