import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' hide State;

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/amount_display.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../core/widgets/keypad.dart';
import '../../../core/widgets/signal_key.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../bloc/bill_amount_bloc.dart';
import '../bloc/bill_amount_event.dart';
import '../bloc/bill_amount_state.dart';
import '../widgets/bill_sheet/bill_sheet_copy.dart';
import 'bill_sheet.dart';

/// The bill amount sheet (D123): a waiting changing or card bill's keypad, prefilled with its
/// estimate, with *Save* and *Didn't go out this month*. Open it with [show].
class BillAmountSheet extends StatelessWidget {
  const BillAmountSheet({super.key});

  static const double _keyHeight = 56;

  /// Opens the sheet for [bloc] over [context] and closes [bloc] once it is done. Completes after
  /// the exit animation with what was done, or [None] when it was closed with Back before a save.
  static Future<Option<BillAmountOutcome>> show(BuildContext context, BillAmountBloc bloc) async {
    final ModalBottomSheetRoute<void> route = BillSheet.route(
      context,
      builder: (BuildContext _) => BlocProvider<BillAmountBloc>.value(value: bloc, child: const BillAmountSheet()),
    );
    await Navigator.of(context).push(route);
    await route.completed;
    // why: Back during a save closes the sheet, but the write still lands; waiting for it keeps
    // its Undo.
    final BillAmountState last = _settled(bloc.state) ? bloc.state : await bloc.stream.firstWhere(_settled);
    unawaited(bloc.close());
    return last is BillAmountDone ? Option<BillAmountOutcome>.of(last.outcome) : const Option<BillAmountOutcome>.none();
  }

  static bool _settled(BillAmountState state) => state is! BillAmountEditing || !state.saving;

  @override
  Widget build(BuildContext context) => BlocConsumer<BillAmountBloc, BillAmountState>(
        listenWhen: (BillAmountState _, BillAmountState current) => current is BillAmountDone,
        listener: (BuildContext context, BillAmountState _) => Navigator.of(context).pop(),
        buildWhen: (BillAmountState _, BillAmountState current) => current is! BillAmountDone,
        builder: (BuildContext context, BillAmountState state) => SingleChildScrollView(
          padding: const EdgeInsetsDirectional.fromSTEB(HisaabSpacing.gutter, 0, HisaabSpacing.gutter, HisaabSpacing.gutter),
          child: state is BillAmountEditing ? _keypad(context, state) : const SizedBox.shrink(),
        ),
      );

  Widget _keypad(BuildContext context, BillAmountEditing state) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final BillAmountBloc bloc = context.read<BillAmountBloc>();
    final RecurringRule rule = state.occurrence.rule;
    final TextStyle? line = Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(strings.billAmountTitle(rule.label, context.shortDate(state.occurrence.date)), style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: HisaabSpacing.m),
        AmountDisplay(amount: Money.fromMajor(state.rupees), rejections: state.rejections),
        const SizedBox(height: HisaabSpacing.s),
        Text(_caption(context, state), style: line),
        // why: a card bill must say why it isn't counted, or the user adds it twice (D123).
        if (rule.amountMode == AmountMode.card) Text(strings.billCardHint, style: line),
        if (state.saveFailed) Text(strings.couldntSave, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: HisaabSpacing.m),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: HisaabChip(
            key: const ValueKey<String>('bill-amount-skip'),
            label: strings.billDidntGoOut,
            onSurface: true,
            onPressed: state.saving ? null : () => bloc.add(const BillAmountSkipPressed()),
          ),
        ),
        const SizedBox(height: HisaabSpacing.m),
        Keypad(
          keyHeight: _keyHeight,
          onKey: (String key) => bloc.add(BillAmountKeyPressed(key)),
          onBackspace: () => bloc.add(const BillAmountBackspacePressed()),
          onClear: () => bloc.add(const BillAmountCleared()),
        ),
        const SizedBox(height: HisaabSpacing.m),
        SignalKey(
          key: const ValueKey<String>('bill-amount-save'),
          label: strings.save,
          onPressed: state.rupees > 0 && !state.saving ? () => bloc.add(const BillAmountSavePressed()) : null,
        ),
      ],
    );
  }

  // why: before the first time there is no "last time"; the prefill is what was guessed at setup.
  static String _caption(BuildContext context, BillAmountEditing state) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return state.lastTime.match(
      () => strings.billAmountYourGuess(context.money.format(state.occurrence.rule.amount)),
      (Money last) => strings.billAmountLastTime(context.money.format(last)),
    );
  }
}
