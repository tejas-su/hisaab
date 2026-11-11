import 'package:material_ui/material_ui.dart';

import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/ledger.dart';
import 'income_copy.dart';

/// What a new payday does, shown before it is saved (SPEC BR-1a, D140): how long the money
/// already received now lasts and about how much each day gets, from Home's own maths in [preview].
class IncomeEffect extends StatelessWidget {
  const IncomeEffect({super.key, required this.preview});

  final CycleSummary preview;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      liveRegion: true,
      child: Column(
        key: const ValueKey<String>('income-effect'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(strings.incomeLastsTill(context.incomeDate(preview.cycle.end)), style: text.titleMedium),
          Text(
            strings.incomeLastsDays(preview.daysLeft, context.money.format(preview.todayShare)),
            style: text.bodyMedium?.copyWith(color: context.colors.ink2),
          ),
        ],
      ),
    );
  }
}
