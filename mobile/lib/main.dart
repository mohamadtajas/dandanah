import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'data/app_services.dart';
import 'startup_error_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _start();
}

Future<void> _start() async {
  final started = Stopwatch()..start();
  try {
    await AppServices.initialize();
    debugPrint(
      'Sakeenah offline data ready in ${started.elapsedMilliseconds} ms',
    );
    runApp(const SakeenahApp());
  } catch (error, stack) {
    debugPrint('Sakeenah startup failed: $error\n$stack');
    runApp(StartupErrorApp(error: error, onRetry: _start));
  }
}
