import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/amount_display.dart';
import '../../../../core/widgets/hisaab_chip.dart';
import '../../../../core/widgets/keypad.dart';
import '../../../../core/widgets/signal_key.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/presentation/rule_glyph.dart';
import '../../bloc/bill_sheet_bloc.dart';
import '../../bloc/bill_sheet_event.dart';
import '../../bloc/bill_sheet_state.dart';
import 'pinned_bill_question.dart';
import 'target_slot.dart';

/// *How much are you saving up to?* (BR-23, AC-T2 to AC-T4): the pinned keypad, empty or prefilled
/// with the target, the [TargetSlot] estimate, and a full-width *Save*, off at ₹0 (F4).
///
/// *Clear* sits in the pinned figure beside the amount (below it at large text, B2), only when a
/// target is set; it removes the target at once.
class TargetQuestion extends StatelessWidget {
  const TargetQuestion({super.key, required this.state});

  final BillSheetReady state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final BillSheetBloc bloc = context.read<BillSheetBloc>();
    final bool canSave = state.rupees > 0 && !state.saving;
    return PinnedBillQuestion(
      question: strings.savingTargetQuestion,
      name: state.rule.label,
      glyph: state.rule.glyph,
      caption: strings.billEveryMonth(state.rule.schedule.anchor.day),
      slot: TargetSlot(state: state),
      saveFailed: state.saveFailed,
      figureExtent: _stacked(context) ? PinnedBillQuestion.stackedChipExtent(context) : PinnedBillQuestion.defaultFigureExtent,
      figure: _figure(context, bloc),
      controls: (BuildContext context, double keyHeight) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Keypad(
            keyHeight: keyHeight,
            onKey: (String key) => bloc.add(BillSheetKeyPressed(key)),
            onBackspace: () => bloc.add(const BillSheetBackspacePressed()),
            onClear: () => bloc.add(const BillSheetCleared()),
          ),
          const SizedBox(height: HisaabSpacing.m),
          SizedBox(
            width: double.infinity,
            child: SignalKey(
              key: const ValueKey<String>('target-save'),
              label: strings.save,
              semanticHint: canSave ? null : strings.typeAmountFirst,
              onPressed: canSave ? () => bloc.add(const BillSheetTargetSaved()) : null,
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasTarget => state.rule.target.isSome();

  bool _stacked(BuildContext context) => _hasTarget && MediaQuery.textScalerOf(context).scale(1) >= PinnedBillQuestion.stackChipFrom;

  Widget _figure(BuildContext context, BillSheetBloc bloc) {
    final Widget amount = AmountDisplay(amount: Money.fromMajor(state.rupees), rejections: state.rejections);
    if (!_hasTarget) {
      return amount;
    }
    final AppLocalizations strings = AppLocalizations.of(context);
    final Widget clear = HisaabChip(
      key: const ValueKey<String>('target-clear'),
      label: strings.savingTargetClear,
      semanticLabel: strings.savingTargetClearSpoken,
      onSurface: true,
      onPressed: state.saving ? null : () => bloc.add(const BillSheetTargetCleared()),
    );
    if (_stacked(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[amount, const SizedBox(height: HisaabSpacing.s), clear],
      );
    }
    return Row(children: <Widget>[Expanded(child: amount), const SizedBox(width: HisaabSpacing.s), clear]);
  }
}
