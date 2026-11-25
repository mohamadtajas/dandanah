import 'package:material_ui/material_ui.dart';

import '../features/adhkar/adhkar_page.dart';
import '../features/audio/audio_page.dart';
import '../features/dashboard/dashboard_page.dart';
import '../features/quran/quran_page.dart';
import '../features/settings/settings_page.dart';
import '../l10n/app_localizations.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.themeMode,
    required this.onThemeChanged,
  });

  final ThemeMode themeMode;
  final ValueChanged<ThemeMode> onThemeChanged;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pages = [
      DashboardPage(onSelectTab: _select),
      const QuranPage(),
      const AdhkarPage(),
      const AudioPage(),
    ];
    final titles = [
      l10n.appTitle,
      l10n.quranPageTitle,
      l10n.adhkarPageTitle,
      l10n.audioPageTitle,
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => SettingsPage(
                  themeMode: widget.themeMode,
                  onThemeChanged: widget.onThemeChanged,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: _index, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home_rounded),
            label: l10n.navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.menu_book_outlined),
            selectedIcon: const Icon(Icons.menu_book_rounded),
            label: l10n.navQuran,
          ),
          NavigationDestination(
            icon: const Icon(Icons.nights_stay_outlined),
            selectedIcon: const Icon(Icons.nights_stay_rounded),
            label: l10n.navAdhkar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.headphones_outlined),
            selectedIcon: const Icon(Icons.headphones_rounded),
            label: l10n.navAudio,
          ),
        ],
      ),
    );
  }
}
