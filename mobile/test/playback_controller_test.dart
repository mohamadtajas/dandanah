import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sakeenah_mobile/data/audio/audio_engine.dart';
import 'package:sakeenah_mobile/data/audio/playback_controller.dart';
import 'package:sakeenah_mobile/data/models/audio.dart';

void main() {
  late _FakeEngine engine;
  late PlaybackController controller;

  setUp(() {
    engine = _FakeEngine();
    controller = PlaybackController(engine);
  });

  tearDown(() => controller.dispose());

  test('playing a surah sets the queue and starts playback', () async {
    await controller.playQueue(_tracks(), initialIndex: 0);

    expect(controller.queue, hasLength(3));
    expect(controller.current?.ayah, 1);
    expect(controller.playing, isTrue);
    expect(engine.playCalls, 1);
  });

  test('toggle, next and previous update the current ayah', () async {
    await controller.playQueue(_tracks());
    await controller.toggle();
    expect(controller.playing, isFalse);

    await controller.next();
    expect(controller.current?.ayah, 2);
    await controller.previous();
    expect(controller.current?.ayah, 1);
  });

  test('speed cycles through the supported values', () async {
    await controller.playQueue(_tracks());
    expect(controller.speed, 1);
    await controller.cycleSpeed();
    expect(controller.speed, 1.25);
    await controller.cycleSpeed();
    expect(controller.speed, 1.5);
    await controller.cycleSpeed();
    expect(controller.speed, 0.75);
  });

  test('repeat cycles off, one, all, off', () async {
    await controller.playQueue(_tracks());
    expect(controller.repeat, AudioRepeatMode.off);
    await controller.cycleRepeat();
    expect(controller.repeat, AudioRepeatMode.one);
    await controller.cycleRepeat();
    expect(controller.repeat, AudioRepeatMode.all);
    await controller.cycleRepeat();
    expect(controller.repeat, AudioRepeatMode.off);
  });

  test('controller notifies listeners on engine state changes', () async {
    var notifications = 0;
    controller.addListener(() => notifications++);

    await controller.playQueue(_tracks());
    await controller.toggle();

    expect(notifications, greaterThan(0));
  });
}

List<AudioTrack> _tracks() => [
  for (var ayah = 1; ayah <= 3; ayah++)
    AudioTrack(
      id: '00100$ayah',
      reciterId: 'test',
      reciterName: 'قارئ',
      surah: 1,
      ayah: ayah,
      surahName: 'الفاتحة',
      url: 'https://example.test/00100$ayah.mp3',
    ),
];

class _FakeEngine implements AudioEngine {
  final _controller = StreamController<AudioEngineState>.broadcast(sync: true);
  AudioEngineState _state = const AudioEngineState();
  int playCalls = 0;

  @override
  Stream<AudioEngineState> get states => _controller.stream;

  @override
  AudioEngineState get current => _state;

  void _emit(AudioEngineState next) {
    _state = next;
    _controller.add(next);
  }

  @override
  Future<void> setQueue(List<AudioTrack> tracks, {int initialIndex = 0}) async {
    _emit(
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
    _emit(_state.copyWith(playing: true));
  }

  @override
  Future<void> pause() async => _emit(_state.copyWith(playing: false));

  @override
  Future<void> seek(Duration position) async =>
      _emit(_state.copyWith(position: position));

  @override
  Future<void> next() async {
    if (_state.index + 1 >= _state.queue.length) return;
    _emit(_state.copyWith(index: _state.index + 1, position: Duration.zero));
  }

  @override
  Future<void> previous() async {
    if (_state.index <= 0) return;
    _emit(_state.copyWith(index: _state.index - 1, position: Duration.zero));
  }

  @override
  Future<void> setSpeed(double speed) async =>
      _emit(_state.copyWith(speed: speed));

  @override
  Future<void> setRepeat(AudioRepeatMode repeat) async =>
      _emit(_state.copyWith(repeat: repeat));

  @override
  Future<void> stop() async => _emit(_state.copyWith(playing: false));

  @override
  Future<void> stopAndClear() async => _emit(const AudioEngineState());

  @override
  Future<void> dispose() async => _controller.close();
}
