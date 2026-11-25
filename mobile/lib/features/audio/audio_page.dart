import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/feature_placeholder.dart';

class AudioPage extends StatelessWidget {
  const AudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return FeaturePlaceholder(
      icon: Icons.headphones_outlined,
      title: l10n.audioPageTitle,
      body: l10n.audioCardBody,
    );
  }
}
