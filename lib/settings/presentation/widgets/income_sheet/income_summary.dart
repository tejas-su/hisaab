import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design/app_icon.dart';
import '../../../../core/design/app_icons.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/time/calendar_date.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../core/widgets/hisaab_chip.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/ledger.dart';
import '../../bloc/income_sheet_bloc.dart';
import '../../bloc/income_sheet_event.dart';
import '../../bloc/income_sheet_state.dart';
import '../bill_sheet/bill_answer_row.dart';
import '../bill_sheet/bill_perforation.dart';
import '../bill_sheet/bill_slip.dart';
import '../bill_sheet/bill_stamp_badge.dart';
import 'income_copy.dart';

/// The income on its paper slip (SPEC FR-SE-1, D137, mockup 32): the monthly amount with the
/// stamp of the latest pay, when it comes, the Amount and *When it comes* rows, and a footer
/// that says when a change counts and offers *Change this month too*. With "It changes" there is
/// no amount, and the footer says how to add money.
class IncomeSummary extends StatelessWidget {
  const IncomeSummary({super.key, required this.state});

  final IncomeSheetReady state;

  @override
  Widget build(BuildContext context) =>
      BillSlip(child: state.income.rule.match(() => _irregular(context), (RecurringRule rule) => _fixed(context, rule)));

  Widget _fixed(BuildContext context, RecurringRule rule) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String amount = context.money.format(IncomeAmount.monthlyOf(rule));
    final String comes = context.incomeComes(rule);
    final String? stamp = state.income.latestPay.map((Entry pay) => strings.incomeStampCame(context.incomeDate(pay.date))).toNullable();
    final String said = strings.spokenAmount(context.money.digits(IncomeAmount.monthlyOf(rule)));
    final String spoken = strings.incomeSlipSpoken(said, comes);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // why: the slip reads as one sentence; the rows below stay separate buttons.
        Semantics(
          container: true,
          label: stamp == null ? spoken : strings.spokenPair(spoken, stamp),
          excludeSemantics: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _eyebrow(context),
              const SizedBox(height: HisaabSpacing.s),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: HisaabSpacing.m,
                children: <Widget>[
                  AmountText(IncomeAmount.monthlyOf(rule), style: Theme.of(context).textTheme.displayMedium),
                  if (stamp != null) BillStampBadge(text: stamp),
                ],
              ),
              _quiet(context, comes),
            ],
          ),
        ),
        const BillPerforation(),
        BillAnswerRow(
          key: const ValueKey<String>('income-row-amount'),
          label: strings.billAnswerAmount,
          value: amount,
          semanticLabel: strings.billChangeSpoken(strings.billAnswerAmount, said),
          flashed: state.justSaved && state.lastsTill.isNone(),
          onPressed: () => context.read<IncomeSheetBloc>().add(const IncomeSheetAmountOpened()),
        ),
        _whenRow(context),
        const BillPerforation(),
        _foot(context, rule),
      ],
    );
  }

  Widget _irregular(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _eyebrow(context),
        const SizedBox(height: HisaabSpacing.s),
        Text(strings.payItChanges, style: Theme.of(context).textTheme.displaySmall),
        _quiet(context, strings.incomeIrregularEvery),
        const BillPerforation(),
        _whenRow(context),
        const BillPerforation(),
        ...state.lastsTill.match(
          () => const <Widget>[],
          (CalendarDate end) => <Widget>[_quiet(context, strings.incomeLastsTill(context.incomeDate(end)))],
        ),
        _quiet(context, strings.incomeIrregularFoot),
      ],
    );
  }

  Widget _whenRow(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String value = context.payRuleWhen(state.payRule);
    return BillAnswerRow(
      key: const ValueKey<String>('income-row-when'),
      label: strings.incomeAnswerWhen,
      value: value,
      semanticLabel: strings.incomeWhenSpoken(value),
      flashed: state.justSaved && state.lastsTill.isSome(),
      onPressed: () => context.read<IncomeSheetBloc>().add(const IncomeSheetWhenOpened()),
    );
  }

  Widget _foot(BuildContext context, RecurringRule rule) => Semantics(
    liveRegion: true,
    child: state.corrected.match(() => _changeFoot(context, rule), (Entry _) => _correctedFoot(context, rule)),
  );

  Widget _changeFoot(BuildContext context, RecurringRule rule) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String date = context.incomeDate(rule.nextDue);
    final TextStyle? strong = _quietStyle(context)?.copyWith(color: context.colors.displayInk, fontWeight: FontWeight.w600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            if (state.justSaved) ...<Widget>[
              AppIcon(AppIcons.check, size: 16, color: context.colors.displayInk),
              const SizedBox(width: 6),
              Text(strings.billSaved, style: strong),
              const SizedBox(width: 6),
            ],
            Expanded(child: _quiet(context, _changeLine(context, date))),
          ],
        ),
        if (state.fixable.isSome()) ...<Widget>[
          const SizedBox(height: HisaabSpacing.s),
          HisaabChip(
            key: const ValueKey<String>('income-this-month-too'),
            label: strings.incomeChangeThisToo(context.incomePeriod(rule)),
            onSurface: true,
            onPressed: () => context.read<IncomeSheetBloc>().add(const IncomeSheetThisMonthChanged()),
          ),
        ],
      ],
    );
  }

  String _changeLine(BuildContext context, String nextPayday) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return state.lastsTill.match(
      () => state.changed ? strings.incomeFromPayday(nextPayday) : strings.incomeNextPayday(nextPayday),
      (CalendarDate end) => strings.incomeLastsTill(context.incomeDate(end)),
    );
  }

  Widget _correctedFoot(BuildContext context, RecurringRule rule) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String now = context.money.format(rule.amount);
    return Row(
      children: <Widget>[
        Expanded(child: _quiet(context, strings.incomeNowIs(context.incomePeriod(rule), now))),
        const SizedBox(width: HisaabSpacing.s),
        HisaabChip(
          key: const ValueKey<String>('income-this-month-undo'),
          label: strings.undo,
          onSurface: true,
          onPressed: () => context.read<IncomeSheetBloc>().add(const IncomeSheetThisMonthUndone()),
        ),
      ],
    );
  }

  Widget _eyebrow(BuildContext context) => Text(AppLocalizations.of(context).moneyComingIn, style: Theme.of(context).textTheme.labelSmall);

  Widget _quiet(BuildContext context, String text) => Text(text, style: _quietStyle(context));

  TextStyle? _quietStyle(BuildContext context) => Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.displayInk2);
}
