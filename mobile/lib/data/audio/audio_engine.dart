import '../models/audio.dart';

class AudioEngineState {
  const AudioEngineState({
    this.queue = const [],
    this.index = 0,
    this.playing = false,
    this.buffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1,
    this.repeat = AudioRepeatMode.off,
    this.error,
  });

  final List<AudioTrack> queue;
  final int index;
  final bool playing;
  final bool buffering;
  final Duration position;
  final Duration duration;
  final double speed;
  final AudioRepeatMode repeat;
  final String? error;

  AudioTrack? get current =>
      index >= 0 && index < queue.length ? queue[index] : null;

  bool get hasNext => index + 1 < queue.length;
  bool get hasPrevious => index > 0;

  AudioEngineState copyWith({
    List<AudioTrack>? queue,
    int? index,
    bool? playing,
    bool? buffering,
    Duration? position,
    Duration? duration,
    double? speed,
    AudioRepeatMode? repeat,
    String? error,
  }) => AudioEngineState(
    queue: queue ?? this.queue,
    index: index ?? this.index,
    playing: playing ?? this.playing,
    buffering: buffering ?? this.buffering,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    speed: speed ?? this.speed,
    repeat: repeat ?? this.repeat,
    error: error ?? this.error,
  );
}

abstract interface class AudioEngine {
  Stream<AudioEngineState> get states;

  AudioEngineState get current;

  Future<void> setQueue(List<AudioTrack> tracks, {int initialIndex = 0});

  Future<void> play();

  Future<void> pause();

  Future<void> seek(Duration position);

  Future<void> next();

  Future<void> previous();

  Future<void> setSpeed(double speed);

  Future<void> setRepeat(AudioRepeatMode repeat);

  Future<void> stop();

  Future<void> dispose();
}
