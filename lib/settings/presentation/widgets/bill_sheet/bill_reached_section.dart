import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/app_icons.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../bloc/bill_sheet_bloc.dart';
import '../../bloc/bill_sheet_event.dart';
import '../../bloc/bill_sheet_state.dart';
import 'bill_wide_key.dart';

/// *I bought it* and *Keep saving*, two `sunk` keys on a saving whose set-aside amount has reached
/// its target, above *Used some of it* (AC-T9, AC-T10, D213). Draws nothing otherwise; closing the
/// sheet leaves the saving as it is (AC-T11). A failed *I bought it* says "Couldn't save. Try again.".
class BillReachedSection extends StatelessWidget {
  const BillReachedSection({super.key, required this.state});

  final BillSheetReady state;

  @override
  Widget build(BuildContext context) {
    if (!state.reached) {
      return const SizedBox.shrink();
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    final BillSheetBloc bloc = context.read<BillSheetBloc>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: HisaabSpacing.s),
        BillWideKey(
          key: const ValueKey<String>('bill-bought'),
          label: strings.savingBoughtIt,
          icon: AppIcons.check,
          onPressed: () => bloc.add(const BillSheetBoughtRequested()),
        ),
        const SizedBox(height: HisaabSpacing.s),
        BillWideKey(
          key: const ValueKey<String>('bill-keep-saving'),
          label: strings.savingKeepSaving,
          icon: AppIcons.recurring,
          onPressed: () => bloc.add(const BillSheetKeepSavingRequested()),
        ),
        if (state.saveFailed) ...<Widget>[
          const SizedBox(height: HisaabSpacing.s),
          Semantics(
            liveRegion: true,
            child: Text(strings.couldntSave, key: const ValueKey<String>('bill-reached-failed'), style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ],
    );
  }
}
