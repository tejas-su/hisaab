import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/design/app_icon.dart';
import '../../../../core/design/app_icons.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/ledger.dart';
import '../../bloc/bill_sheet_bloc.dart';
import '../../bloc/bill_sheet_event.dart';
import '../../bloc/bill_sheet_state.dart';
import 'bill_answer_row.dart';
import 'bill_head.dart';
import 'bill_perforation.dart';
import 'bill_sheet_copy.dart';
import 'bill_slip.dart';
import 'bill_stamp_badge.dart';
import 'bill_wide_key.dart';

/// The whole bill on its slip: head, amount and stamp, the four answer rows, the next date,
/// then *Delete bill* (SPEC FR-SE-1 AC-2, AC-6).
class BillSummary extends StatelessWidget {
  const BillSummary({super.key, required this.state});

  final BillSheetReady state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final RecurringRule rule = state.rule;
    final String? stamp = state.status.map(context.stampText).toNullable();
    final String spoken = strings.billSlipSpoken(rule.label, context.iconName(rule.shownIcon), context.spokenMoney(rule), _day(rule));
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        BillSlip(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // why: the bill reads as one sentence; the rows below stay separate buttons.
              Semantics(
                container: true,
                label: stamp == null ? spoken : strings.spokenPair(spoken, stamp),
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(strings.billSheetEyebrow, style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: HisaabSpacing.m),
                    BillHead(name: rule.label, icon: rule.shownIcon),
                    const SizedBox(height: 10),
                    _amountLine(context, stamp),
                    Text(
                      strings.billEveryMonth(_day(rule)),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.displayInk2),
                    ),
                  ],
                ),
              ),
              const BillPerforation(),
              ..._rows(context),
              const BillPerforation(),
              _foot(context),
            ],
          ),
        ),
        const SizedBox(height: HisaabSpacing.s),
        BillWideKey(
          key: const ValueKey<String>('bill-delete'),
          label: strings.deleteBill,
          icon: AppIcons.delete,
          onPressed: () => context.read<BillSheetBloc>().add(const BillSheetDeleteRequested()),
        ),
      ],
    );
  }

  static int _day(RecurringRule rule) => rule.schedule.anchor.day;

  Widget _amountLine(BuildContext context, String? stamp) => Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: HisaabSpacing.m,
        children: <Widget>[
          AmountText(state.rule.amount, style: Theme.of(context).textTheme.displayMedium),
          if (stamp != null) BillStampBadge(text: stamp),
        ],
      );

  List<Widget> _rows(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final RecurringRule rule = state.rule;
    final String amount = context.money.format(rule.amount);
    final String icon = context.iconName(rule.shownIcon);
    return <Widget>[
      _row(context, BillAnswer.amount, strings.billAnswerAmount, amount, spoken: context.spokenMoney(rule)),
      _row(context, BillAnswer.day, strings.billAnswerDay, '${_day(rule)}'),
      _row(context, BillAnswer.name, strings.billAnswerName, rule.label),
      _row(context, BillAnswer.icon, strings.billAnswerIcon, icon, leading: rule.shownIcon.glyph),
    ];
  }

  Widget _row(BuildContext context, BillAnswer answer, String label, String value, {String? spoken, AppIconData? leading}) =>
      BillAnswerRow(
        key: ValueKey<String>('bill-row-${answer.name}'),
        label: label,
        value: value,
        leading: leading,
        semanticLabel: AppLocalizations.of(context).billChangeSpoken(label, spoken ?? value),
        flashed: state.justSaved == Option<BillAnswer>.of(answer),
        onPressed: () => context.read<BillSheetBloc>().add(BillSheetAnswerOpened(answer)),
      );

  Widget _foot(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.displayInk2);
    final String? next = state.status.map((BillStatus status) => strings.billNextGoesOut(context.shortDate(status.nextDate))).toNullable();
    return Semantics(
      liveRegion: true,
      child: Row(
        children: <Widget>[
          if (state.justSaved.isSome()) ...<Widget>[
            AppIcon(AppIcons.check, size: 16, color: context.colors.displayInk),
            const SizedBox(width: 6),
            Text(strings.billSaved, style: style?.copyWith(color: context.colors.displayInk, fontWeight: FontWeight.w600)),
            const SizedBox(width: 6),
          ],
          if (next != null) Expanded(child: Text(next, style: style)),
        ],
      ),
    );
  }
}
