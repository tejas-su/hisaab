import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/amount_display.dart';
import '../../../../core/widgets/hisaab_back_button.dart';
import '../../../../core/widgets/hisaab_chip.dart';
import '../../../../core/widgets/keypad.dart';
import '../../../../core/widgets/signal_key.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/ledger.dart';
import '../../../../ledger/presentation/rule_glyph.dart';
import '../../bloc/used_bloc.dart';
import '../../bloc/used_event.dart';
import '../../bloc/used_state.dart';
import 'pinned_bill_question.dart';
import 'used_all_chip.dart';
import 'used_slot.dart';

/// *How much did you use from {saving}?* (BR-19, AC-Y6): the amount starts empty, *All of it* fills
/// what is set aside, the slot says what will stay, and a full-width *Save* sits under the keypad.
/// Reads its state from the [UsedBloc] above it; [rule] is the saving.
class UsedQuestion extends StatelessWidget {
  const UsedQuestion({super.key, required this.rule});

  final RecurringRule rule;

  /// The text scale from which *All of it* drops below the amount instead of sitting beside it.
  static const double _stackChipFrom = 1.3;
  static const double _chipExtent = 48 + HisaabSpacing.s;
  static const double _actionKeyGrowth = 16;

  @override
  Widget build(BuildContext context) => BlocBuilder<UsedBloc, UsedState>(
        builder: (BuildContext context, UsedState state) => switch (state) {
          UsedReady() => _keypad(context, state),
          UsedFailed() => _failed(context),
          UsedLoading() || UsedDone() => const SizedBox.shrink(),
        },
      );

  // why: the body multiplies the figure's extent by the text scale, but the slip's chrome and the
  // chip do not grow with it, so each is divided by the scale first. The action key does grow with
  // large text past the body's fixed estimate (74dp at 2.0x), so that growth is added too: a window
  // too short for it then hands over to the all-scrolling layout instead of overflowing.
  static double _stackedFigureExtent(BuildContext context) {
    final double scale = MediaQuery.textScalerOf(context).scale(1);
    return (PinnedBillQuestion.slipChrome + _chipExtent + _actionKeyGrowth) / scale + PinnedBillQuestion.amountExtent;
  }

  Widget _keypad(BuildContext context, UsedReady state) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final UsedBloc bloc = context.read<UsedBloc>();
    final bool stacked = MediaQuery.textScalerOf(context).scale(1) >= _stackChipFrom;
    final Widget amount = AmountDisplay(amount: Money.fromMajor(state.rupees), rejections: state.rejections);
    final Widget chip = UsedAllChip(
      selected: state.allSelected,
      onPressed: state.nothingToUse || state.writing ? null : () => bloc.add(const UsedAllPressed()),
    );
    return PinnedBillQuestion(
      question: strings.savingUsedQuestion(rule.label),
      name: rule.label,
      glyph: rule.glyph,
      caption: strings.billEveryMonth(rule.schedule.anchor.day),
      slot: UsedSlot(state: state),
      saveFailed: state.saveFailed,
      figureExtent: stacked ? _stackedFigureExtent(context) : PinnedBillQuestion.defaultFigureExtent,
      figure: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[amount, const SizedBox(height: HisaabSpacing.s), chip],
            )
          : Row(
              children: <Widget>[
                Expanded(child: amount),
                const SizedBox(width: HisaabSpacing.s),
                chip,
              ],
            ),
      controls: (BuildContext context, double keyHeight) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Keypad(
            keyHeight: keyHeight,
            onKey: (String key) => bloc.add(UsedKeyPressed(key)),
            onBackspace: () => bloc.add(const UsedBackspacePressed()),
            onClear: () => bloc.add(const UsedCleared()),
          ),
          const SizedBox(height: HisaabSpacing.m),
          SizedBox(
            width: double.infinity,
            child: SignalKey(
              key: const ValueKey<String>('used-save'),
              label: strings.save,
              semanticHint: state.canSave ? null : strings.typeAmountFirst,
              onPressed: state.canSave ? () => bloc.add(const UsedSavePressed()) : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _failed(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const HisaabBackButton(),
          const SizedBox(height: HisaabSpacing.m),
          Text(strings.loadFailed, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: HisaabSpacing.m),
          HisaabChip(
            label: strings.tryAgain,
            onSurface: true,
            onPressed: () => context.read<UsedBloc>().add(UsedLoadRequested(rule)),
          ),
          const SizedBox(height: HisaabSpacing.l),
        ],
      ),
    );
  }
}
