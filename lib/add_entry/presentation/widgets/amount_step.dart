import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/widgets/adaptive_split.dart';
import '../../../core/widgets/amount_cap_ring.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/keypad.dart';
import '../../../core/widgets/shake.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/add_entry_bloc.dart';
import '../bloc/add_entry_event.dart';
import '../bloc/add_entry_state.dart';
import 'kind_switch.dart';
import 'quick_add_chips.dart';
import 'usual_slot.dart';

/// Step 1 of the tray: Spent/Got, the amount, the slot for *your usual* or the amount's effect
/// on today, quick chips, keypad, Next (SPEC FR-AD-1 to FR-AD-4, FR-AD-10).
class AmountStep extends StatelessWidget {
  const AmountStep({super.key, required this.state, this.sideBySide = false});

  /// The tray's state on step 1: editing, or saving and finished after a pill tap, when the
  /// step stays in view while the tray closes (FR-AD-10 AC-4).
  final AddEntryState state;

  /// The gap from Spent/Got to the amount in a tall tray (UI_DESIGN §5.3, layout B).
  static const double _aboveAmount = 20;

  /// Amount beside the keypad, for the short, wide tray below a tabletop fold.
  final bool sideBySide;

  /// The header's height at 1x text (Spent/Got, amount, slot, chips) and the stacked controls'
  /// (4 keys of 64dp, gaps, Next, padding): the tray goes side by side when both don't fit.
  static const double _headerExtent = 220;
  static const double _stackedControlsExtent = 4 * HisaabSizes.keypadKeyHeight + 3 * HisaabSpacing.s + 14 + SignalKey.minHeight + 48;

  /// Below this width the halves are too narrow, so the tray stays stacked and scrolls.
  static const double _sideBySideMinWidth = 360;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (BuildContext context, BoxConstraints box) {
      final double needed = MediaQuery.textScalerOf(context).scale(_headerExtent) + _stackedControlsExtent;
      final bool crowded = box.hasBoundedHeight && box.maxWidth >= _sideBySideMinWidth && box.maxHeight < needed;
      return _body(context, sideBySide || crowded);
    },
  );

  Widget _body(BuildContext context, bool sideBySide) {
    final AddEntryBloc bloc = context.read<AddEntryBloc>();
    final bool short = sideBySide || context.layout.heightClass == HeightClass.compact;
    final AddEntryState current = state;
    return AdaptiveSplit(
      fullWindow: false,
      sideBySide: sideBySide,
      header: Column(
        children: <Widget>[
          KindSwitch(kind: state.form.kind, onChanged: (EntryKind kind) => bloc.add(AddEntryKindChanged(kind))),
          SizedBox(height: short ? HisaabSpacing.m : _aboveAmount),
          AmountCapRing(
            rejections: current is AddEntryEditing ? current.rejections : 0,
            amount: state.form.amount,
            child: Shake(
              trigger: current is AddEntryEditing ? current.rejections : 0,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AmountText(state.form.amount, roll: false, style: Theme.of(context).textTheme.displayMedium),
              ),
            ),
          ),
          const SizedBox(height: HisaabSpacing.xs),
          UsualSlot(key: const ValueKey<String>('usual-slot'), state: state),
          const SizedBox(height: HisaabSpacing.s),
          QuickAddChips(onAdd: (int rupees) => bloc.add(AddEntryQuickAdded(rupees))),
        ],
      ),
      controls: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Keypad(
            keyHeight: short ? HisaabSizes.minTouchTarget : HisaabSizes.keypadKeyHeight,
            onKey: (String key) => bloc.add(AddEntryKeyPressed(key)),
            onBackspace: () => bloc.add(const AddEntryBackspacePressed()),
            onClear: () => bloc.add(const AddEntryCleared()),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: SignalKey(
              key: const ValueKey<String>('add-next'),
              label: AppLocalizations.of(context).next,
              icon: AppIcons.next,
              onPressed: state.form.rupees > 0 ? () => bloc.add(const AddEntryNextPressed()) : null,
            ),
          ),
        ],
      ),
    );
  }
}
