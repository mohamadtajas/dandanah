import 'package:audio_service/audio_service.dart';
import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'data/app_services.dart';
import 'data/audio/audio_engine.dart';
import 'data/audio/just_audio_engine.dart';
import 'data/audio/playback_controller.dart';
import 'startup_error_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _start();
}

Future<void> _start() async {
  final started = Stopwatch()..start();
  try {
    final AudioEngine engine = await _audioEngine();
    await AppServices.initialize(playback: PlaybackController(engine));
    debugPrint(
      'Sakeenah offline data ready in ${started.elapsedMilliseconds} ms',
    );
    runApp(const SakeenahApp());
  } catch (error, stack) {
    debugPrint('Sakeenah startup failed: $error\n$stack');
    runApp(StartupErrorApp(error: error, onRetry: _start));
  }
}

Future<AudioEngine> _audioEngine() async {
  try {
    return await AudioService.init(
      builder: JustAudioEngine.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'app.sakeenah.mobile.audio',
        androidNotificationChannelName: 'Sakeenah',
        androidNotificationOngoing: true,
      ),
    ) as AudioEngine;
  } catch (error) {
    debugPrint('Background audio unavailable: $error');
    return JustAudioEngine();
  }
}
