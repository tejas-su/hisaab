import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/app_icons.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/presentation/rule_words.dart';
import '../../bloc/bill_sheet_bloc.dart';
import '../../bloc/bill_sheet_event.dart';
import '../../bloc/bill_sheet_state.dart';
import 'bill_wide_key.dart';

/// The outlined *Used some of it* key in the middle of a saving's sheet, and on the three yearly
/// costs the hint above it (AC-Y5). Draws nothing until at least ₹1 is set aside, so before the
/// first put-in the sheet is as it was.
class BillUsedSection extends StatelessWidget {
  const BillUsedSection({super.key, required this.state});

  final BillSheetReady state;

  @override
  Widget build(BuildContext context) {
    final Money? setAside = state.setAside.toNullable();
    if (setAside == null || setAside.floorMajor < 1) {
      return const SizedBox.shrink();
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: HisaabSpacing.s),
        if (strings.isYearlyCostName(state.rule.label)) ...<Widget>[
          Text(
            strings.savingUsedHint,
            key: const ValueKey<String>('bill-used-hint'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.displayInk2),
          ),
          const SizedBox(height: HisaabSpacing.s),
        ],
        BillWideKey(
          key: const ValueKey<String>('bill-used'),
          label: strings.savingUsedAction,
          icon: AppIcons.saving,
          outlined: true,
          semanticHint: strings.waitingOpensHint,
          onPressed: () => context.read<BillSheetBloc>().add(const BillSheetAnswerOpened(BillAnswer.used)),
        ),
      ],
    );
  }
}
