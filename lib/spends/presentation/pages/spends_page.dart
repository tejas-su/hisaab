import 'package:flutter/material.dart';

import '../../../core/widgets/screen_in_progress.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Spends: where the money went, the pace chart, Ask AI (SPEC FR-SP). Placeholder until M4.
class SpendsPage extends StatelessWidget {
  const SpendsPage({super.key});

  @override
  Widget build(BuildContext context) => ScreenInProgress(title: AppLocalizations.of(context).navSpends);
}
