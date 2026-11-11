import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/display_card.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The hero when there is no money to share yet (SPEC BR-5 #1, E10): one sentence and one key
/// that opens the Add tray on *Got*.
class NoIncomeCard extends StatelessWidget {
  const NoIncomeCard({super.key, required this.onAddMoney});

  final VoidCallback onAddMoney;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return DisplayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.noIncomeTitle, style: text.titleLarge?.copyWith(color: context.colors.displayInk)),
          const SizedBox(height: HisaabSpacing.xs),
          Text(strings.noIncomeBody, style: text.bodyMedium?.copyWith(color: context.colors.displayInk2)),
          const SizedBox(height: HisaabSpacing.l),
          SignalKey(label: strings.addMoney, icon: AppIcons.add, onPressed: onAddMoney),
        ],
      ),
    );
  }
}
