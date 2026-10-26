import 'package:flutter/material.dart';

import '../../../core/widgets/screen_in_progress.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Home: safe to spend today, Day Blocks, the Today list (SPEC FR-HO). Placeholder until M1.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => ScreenInProgress(title: AppLocalizations.of(context).navHome);
}
