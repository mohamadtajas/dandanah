import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'data/app_services.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final started = Stopwatch()..start();
  await AppServices.initialize();
  debugPrint(
    'Sakeenah offline data ready in ${started.elapsedMilliseconds} ms',
  );
  runApp(const SakeenahApp());
}
