import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/feature_placeholder.dart';

class AdhkarPage extends StatelessWidget {
  const AdhkarPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FeaturePlaceholder(
      icon: Icons.nights_stay_outlined,
      title: l10n.adhkarPageTitle,
      body: l10n.adhkarCardBody,
    );
  }
}
