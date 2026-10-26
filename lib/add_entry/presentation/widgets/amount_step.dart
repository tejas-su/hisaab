import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/widgets/adaptive_split.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/keypad.dart';
import '../../../core/widgets/shake.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../cubit/add_entry_cubit.dart';
import '../cubit/add_entry_state.dart';
import 'kind_switch.dart';
import 'quick_add_chips.dart';
import 'spend_preview_line.dart';

/// Step 1 of the tray: Spent/Got, the amount, its effect on today, quick chips, keypad, Next
/// (SPEC FR-AD-1 to FR-AD-4).
class AmountStep extends StatelessWidget {
  const AmountStep({super.key, required this.state, required this.fullWindow});

  final AddEntryEditing state;

  /// The tray fills the window (tabletop posture), so the keypad goes below the fold.
  final bool fullWindow;

  @override
  Widget build(BuildContext context) {
    final AddEntryCubit cubit = context.read<AddEntryCubit>();
    final bool short = context.layout.heightClass == HeightClass.compact;
    return AdaptiveSplit(
      fullWindow: fullWindow,
      header: Column(
        children: <Widget>[
          KindSwitch(kind: state.form.kind, onChanged: cubit.setKind),
          SizedBox(height: short ? HisaabSpacing.m : 30),
          Shake(
            trigger: state.rejections,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AmountText(state.form.amount, roll: false, style: Theme.of(context).textTheme.displayMedium),
            ),
          ),
          const SizedBox(height: 6),
          SpendPreviewLine(preview: state.form.preview),
          const SizedBox(height: HisaabSpacing.l),
          QuickAddChips(onAdd: cubit.quickAdd),
        ],
      ),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Keypad(
            keyHeight: short ? HisaabSizes.minTouchTarget : HisaabSizes.keypadKeyHeight,
            onKey: cubit.pressKey,
            onBackspace: cubit.backspace,
            onClear: cubit.clear,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SignalKey(
              key: const ValueKey<String>('add-next'),
              label: AppLocalizations.of(context).next,
              icon: AppIcons.next,
              onPressed: state.form.rupees > 0 ? cubit.next : null,
            ),
          ),
        ],
      ),
    );
  }
}
