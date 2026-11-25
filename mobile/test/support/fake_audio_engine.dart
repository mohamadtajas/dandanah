import 'dart:async';

import 'package:sakeenah_mobile/data/audio/audio_engine.dart';
import 'package:sakeenah_mobile/data/models/audio.dart';

class FakeAudioEngine implements AudioEngine {
  final _controller = StreamController<AudioEngineState>.broadcast(sync: true);
  AudioEngineState _state = const AudioEngineState();
  int playCalls = 0;

  @override
  Stream<AudioEngineState> get states => _controller.stream;

  @override
  AudioEngineState get current => _state;

  void emit(AudioEngineState next) {
    _state = next;
    _controller.add(next);
  }

  @override
  Future<void> setQueue(List<AudioTrack> tracks, {int initialIndex = 0}) async {
    emit(
      _state.copyWith(
        queue: tracks,
        index: initialIndex,
        position: Duration.zero,
        playing: false,
      ),
    );
  }

  @override
  Future<void> play() async {
    playCalls++;
    emit(_state.copyWith(playing: true));
  }

  @override
  Future<void> pause() async => emit(_state.copyWith(playing: false));

  @override
  Future<void> seek(Duration position) async =>
      emit(_state.copyWith(position: position));

  @override
  Future<void> next() async {
    if (_state.index + 1 >= _state.queue.length) return;
    emit(_state.copyWith(index: _state.index + 1, position: Duration.zero));
  }

  @override
  Future<void> previous() async {
    if (_state.index <= 0) return;
    emit(_state.copyWith(index: _state.index - 1, position: Duration.zero));
  }

  @override
  Future<void> setSpeed(double speed) async =>
      emit(_state.copyWith(speed: speed));

  @override
  Future<void> setRepeat(AudioRepeatMode repeat) async =>
      emit(_state.copyWith(repeat: repeat));

  @override
  Future<void> stop() async => emit(_state.copyWith(playing: false));

  @override
  Future<void> dispose() async => _controller.close();
}
