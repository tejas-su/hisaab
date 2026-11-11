import 'package:material_ui/material_ui.dart';

import '../../core/design/hisaab_dimensions.dart';
import '../../l10n/gen/app_localizations.dart';

/// Shown instead of the app when the local database can't be opened at start-up.
class StartupFailureView extends StatelessWidget {
  const StartupFailureView({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(HisaabSpacing.xl),
              child: Text(
                AppLocalizations.of(context).startupFailed,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
        ),
      );
}
