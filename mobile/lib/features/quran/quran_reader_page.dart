import 'package:material_ui/material_ui.dart';

import '../../data/app_services.dart';
import '../../l10n/app_localizations.dart';

class QuranReaderPage extends StatefulWidget {
  const QuranReaderPage.surah({
    super.key,
    required int this.surah,
    this.initialAyah,
  }) : juz = null;

  const QuranReaderPage.juz({
    super.key,
    required int this.juz,
    this.initialAyah,
  }) : surah = null;

  final int? surah;
  final int? juz;
  final int? initialAyah;

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  late final AppServices _services = AppServices.current;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.surah != null) {
        await _services.quran.ayahsForSurah(widget.surah!);
      } else {
        await _services.quran.ayahsForJuz(widget.juz!);
      }
    } catch (error) {
      _error = error;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(l10n.quranReaderError))
          : Center(child: Text(l10n.quranContinue)),
    );
  }
}
