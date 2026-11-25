import 'package:cupertino_ui/cupertino_ui.dart'
    show GlobalCupertinoLocalizations;
import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;
import 'package:material_ui/material_ui.dart';

import 'l10n/app_localizations.dart';
import 'shell/app_shell.dart';
import 'theme/sakeenah_theme.dart';

class SakeenahApp extends StatefulWidget {
  const SakeenahApp({super.key});

  @override
  State<SakeenahApp> createState() => _SakeenahAppState();
}

class _SakeenahAppState extends State<SakeenahApp> {
  ThemeMode _mode = ThemeMode.dark;

  void _setTheme(ThemeMode mode) => setState(() => _mode = mode);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      locale: const Locale('ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: SakeenahTheme.light(),
      darkTheme: SakeenahTheme.dark(),
      themeMode: _mode,
      home: AppShell(themeMode: _mode, onThemeChanged: _setTheme),
    );
  }
}
