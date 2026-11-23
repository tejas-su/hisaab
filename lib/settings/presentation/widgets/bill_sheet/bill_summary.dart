import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/design/app_icon.dart';
import '../../../../core/design/app_icons.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../core/widgets/amount_text.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/ledger.dart';
import '../../../../ledger/presentation/rule_glyph.dart';
import '../../../../ledger/presentation/rule_words.dart';
import '../../bloc/bill_sheet_bloc.dart';
import '../../bloc/bill_sheet_event.dart';
import '../../bloc/bill_sheet_state.dart';
import 'bill_answer_row.dart';
import 'bill_head.dart';
import 'bill_perforation.dart';
import 'bill_sheet_copy.dart';
import 'bill_slip.dart';
import 'bill_reached_section.dart';
import 'bill_used_section.dart';
import '../saving_target_copy.dart';
import 'bill_stamp_badge.dart';
import 'bill_wide_key.dart';

/// The whole bill on its slip: head, amount and stamp, the answer rows (with *Kind of bill*, D123), the next date,
/// then *Delete bill* (SPEC FR-SE-1 AC-2, AC-6). A saving has no Icon row and says "goes in"
/// and "put in" (D120); it ends its rows with *Saving up to* (AC-T1), and its set-aside line
/// reads as its Savings row does (AC-T6). A saving that reached its target has stopped putting
/// in, so it draws no stamp and no next date (D213).
class BillSummary extends StatelessWidget {
  const BillSummary({super.key, required this.state});

  final BillSheetReady state;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final RecurringRule rule = state.rule;
    final String? stamp = state.reached
        ? null
        : state.status.map((BillStatus status) => context.stampText(status, kind: rule.kind, mode: rule.amountMode)).toNullable();
    final SpokenLine? aside = _setAsideLine(context);
    final String slip = _isSaving
        ? strings.savingSlipSpoken(rule.label, context.spokenMoney(rule), _day(rule))
        : strings.billSlipSpoken(rule.label, context.iconName(rule.shownIcon), context.spokenMoney(rule), _day(rule));
    final String spoken =
        aside == null ? slip : strings.spokenPair(slip, aside.spoken);
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
                    Text(strings.ruleEyebrow(rule.kind), style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: HisaabSpacing.m),
                    BillHead(name: rule.label, glyph: rule.glyph),
                    const SizedBox(height: 10),
                    _amountLine(context, stamp),
                    if (aside != null)
                      Text(
                        aside.shown,
                        key: const ValueKey<String>('bill-set-aside'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.displayInk2),
                      ),
                    Text(
                      strings.billEveryMonth(_day(rule)),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.displayInk2),
                    ),
                  ],
                ),
              ),
              const BillPerforation(),
              ..._rows(context),
              BillReachedSection(state: state),
              BillUsedSection(state: state),
              const BillPerforation(),
              _foot(context),
            ],
          ),
        ),
        const SizedBox(height: HisaabSpacing.s),
        BillWideKey(
          key: const ValueKey<String>('bill-delete'),
          label: strings.ruleDelete(rule.kind),
          icon: AppIcons.delete,
          onPressed: () => context.read<BillSheetBloc>().add(const BillSheetDeleteRequested()),
        ),
      ],
    );
  }

  static int _day(RecurringRule rule) => rule.schedule.anchor.day;

  bool get _isSaving => state.rule.kind == EntryKind.saved;

  // why: "set aside" shows only above ₹0, so a saving that never had a put-in reads as before (AC-Y5).
  Money? get _shownSetAside {
    final Money? aside = state.setAside.toNullable();
    return aside != null && aside > Money.zero ? aside : null;
  }

  // why: with a target the line follows BR-23's table, which names the target even before the
  // first put-in (AC-T6); the visible dot and no-break space are never read (B4).
  SpokenLine? _setAsideLine(BuildContext context) {
    final Money? aside = _shownSetAside;
    final AppLocalizations strings = AppLocalizations.of(context);
    final SpokenLine? plain = aside == null
        ? null
        : (shown: strings.savingSetAside(context.money.format(aside)), spoken: strings.savingSetAside(strings.spokenAmount(context.money.digits(aside))));
    final Option<SpokenLine> line = state.rule.target.flatMap(
      (Money target) => state.targetProgress.map(
        (TargetProgress progress) =>
            context.targetLine(progress: progress, target: target, setAside: aside ?? Money.zero, today: state.today),
      ),
    );
    return line.toNullable() ?? plain;
  }

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
      // why: a saving always goes in by itself, so only a bill asks whether its amount changes (D123).
      if (!_isSaving) _row(context, BillAnswer.mode, strings.billModeRow, strings.amountModeName(rule.amountMode)),
      _row(context, BillAnswer.day, strings.billAnswerDay, '${_day(rule)}'),
      _row(context, BillAnswer.name, strings.billAnswerName, rule.label),
      // why: a saving always shows the piggy bank, so it has no icon to change (D120).
      if (!_isSaving) _row(context, BillAnswer.icon, strings.billAnswerIcon, icon, leading: rule.shownIcon.glyph),
      if (_isSaving) _targetRow(context, strings),
    ];
  }

  Widget _targetRow(BuildContext context, AppLocalizations strings) => state.rule.target.match(
        () => _row(context, BillAnswer.target, strings.savingTargetLabel, strings.savingTargetNotSet, semanticLabel: strings.savingTargetRowNotSet),
        (Money target) => _row(
          context,
          BillAnswer.target,
          strings.savingTargetLabel,
          context.money.format(target),
          semanticLabel: strings.savingTargetRowSet(strings.spokenAmount(context.money.digits(target))),
        ),
      );

  Widget _row(
    BuildContext context,
    BillAnswer answer,
    String label,
    String value, {
    String? spoken,
    String? semanticLabel,
    AppIconData? leading,
  }) =>
      BillAnswerRow(
        key: ValueKey<String>('bill-row-${answer.name}'),
        label: label,
        value: value,
        leading: leading,
        semanticLabel: semanticLabel ?? AppLocalizations.of(context).billChangeSpoken(label, spoken ?? value),
        flashed: state.justSaved == Option<BillAnswer>.of(answer),
        onPressed: () => context.read<BillSheetBloc>().add(BillSheetAnswerOpened(answer)),
      );

  Widget _foot(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextStyle? style = Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.displayInk2);
    final String? next = state.reached
        ? null
        : state.status.map((BillStatus status) => context.footText(status, kind: state.rule.kind, mode: state.rule.amountMode)).toNullable();
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
