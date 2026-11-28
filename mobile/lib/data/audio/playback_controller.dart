import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../models/audio.dart';
import 'audio_engine.dart';

class PlaybackController extends ChangeNotifier {
  PlaybackController(this._engine) {
    _state = _engine.current;
    _subscription = _engine.states.listen((state) {
      _state = state;
      notifyListeners();
    });
  }

  static const speeds = [0.75, 1.0, 1.25, 1.5];

  final AudioEngine _engine;
  late final StreamSubscription<AudioEngineState> _subscription;
  AudioEngineState _state = const AudioEngineState();

  AudioEngineState get state => _state;
  List<AudioTrack> get queue => _state.queue;
  AudioTrack? get current => _state.current;
  bool get playing => _state.playing;
  bool get buffering => _state.buffering;
  Duration get position => _state.position;
  Duration get duration => _state.duration;
  double get speed => _state.speed;
  AudioRepeatMode get repeat => _state.repeat;
  String? get error => _state.error;

  Future<void> playQueue(
    List<AudioTrack> tracks, {
    int initialIndex = 0,
  }) async {
    await _engine.setQueue(tracks, initialIndex: initialIndex);
    await _engine.play();
  }

  Future<void> play() => _engine.play();

  Future<void> pause() => _engine.pause();

  Future<void> toggle() => _state.playing ? pause() : play();

  Future<void> next() => _state.hasNext ? _engine.next() : Future.value();

  Future<void> previous() =>
      _state.hasPrevious ? _engine.previous() : Future.value();

  Future<void> seek(Duration position) => _engine.seek(position);

  Future<void> setSpeed(double speed) => _engine.setSpeed(speed);

  Future<void> cycleSpeed() {
    final index = speeds.indexOf(_state.speed);
    final next = speeds[(index < 0 ? 1 : index + 1) % speeds.length];
    return setSpeed(next);
  }

  Future<void> setRepeat(AudioRepeatMode repeat) => _engine.setRepeat(repeat);

  Future<void> cycleRepeat() {
    final next = switch (_state.repeat) {
      AudioRepeatMode.off => AudioRepeatMode.one,
      AudioRepeatMode.one => AudioRepeatMode.all,
      AudioRepeatMode.all => AudioRepeatMode.off,
    };
    return setRepeat(next);
  }

  int get index => _state.index;

  Future<void> playAt(int index, {Duration position = Duration.zero}) =>
      _engine.playAt(index, position: position);

  Future<void> stop() => _engine.stop();

  Future<void> stopAndClear() => _engine.stopAndClear();

  /// Re-applies the current queue when the initial load failed.
  Future<void> retry() async {
    final index = _state.index;
    if (queue.isEmpty) {
      return play();
    }
    await _engine.setQueue(queue, initialIndex: index);
    await _engine.play();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _engine.dispose();
    super.dispose();
  }
}
