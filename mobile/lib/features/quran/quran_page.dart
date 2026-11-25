import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/sakeenah_theme.dart';
import '../../widgets/feature_placeholder.dart';

class QuranPage extends StatelessWidget {
  const QuranPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return FeaturePlaceholder(
      icon: Icons.menu_book_outlined,
      title: l10n.quranPageTitle,
      body: l10n.quranCardBody,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: SakeenahTheme.quran(
                  Theme.of(context).textTheme.titleLarge!,
                  size: 24,
                ).copyWith(color: scheme.onSurface),
              ),
              const SizedBox(height: 14),
              Text(
                'ٱلْحَمْدُ لِلَّهِ رَبِّ ٱلْعَٰلَمِينَ',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: SakeenahTheme.quran(
                  Theme.of(context).textTheme.titleLarge!,
                  size: 26,
                ).copyWith(color: scheme.primary),
              ),
              const SizedBox(height: 14),
              Text(
                'الفاتحة · أول آيتين',
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
