import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/sakeenah_theme.dart';
import '../../widgets/feature_card.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key, required this.onSelectTab});

  final ValueChanged<int> onSelectTab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: scheme.outline),
            gradient: LinearGradient(
              begin: AlignmentDirectional.topStart,
              end: AlignmentDirectional.bottomEnd,
              colors: [
                scheme.primary.withValues(alpha: 0.15),
                scheme.surface,
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.nightlight_round, color: scheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.appTitle,
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.2,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                l10n.dashboardWelcome,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.dashboardSubtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.7,
                    ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(Icons.menu_book_rounded,
                      size: 15, color: scheme.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'إِنَّا أَعْطَيْنَاكَ الْكَوْثَرَ',
                      textDirection: TextDirection.rtl,
                      style: SakeenahTheme.quran(
                        Theme.of(context).textTheme.titleLarge!,
                        size: 24,
                      ).copyWith(
                        color: scheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: FeatureCard(
                    icon: Icons.mosque_outlined,
                    title: l10n.prayerCardTitle,
                    body: l10n.prayerCardBody,
                    badge: l10n.comingSoon,
                  ),
                ),
                SizedBox(
                  width: width,
                  child: FeatureCard(
                    icon: Icons.menu_book_outlined,
                    title: l10n.quranCardTitle,
                    body: l10n.quranCardBody,
                    onTap: () => onSelectTab(1),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: FeatureCard(
                    icon: Icons.nights_stay_outlined,
                    title: l10n.adhkarCardTitle,
                    body: l10n.adhkarCardBody,
                    onTap: () => onSelectTab(2),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: FeatureCard(
                    icon: Icons.headphones_outlined,
                    title: l10n.audioCardTitle,
                    body: l10n.audioCardBody,
                    onTap: () => onSelectTab(3),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
