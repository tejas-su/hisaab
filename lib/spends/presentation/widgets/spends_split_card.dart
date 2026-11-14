import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/hisaab_chip.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/money_split.dart';
import '../month_story_copy.dart';
import 'spends_card.dart';
import 'split_bar_painter.dart';

/// The split card (SPEC FR-SP-4b, BR-21): money in, then the answer ("₹16,430 not spent yet"), the
/// bar and a two-row key. With nothing in, only the prompt and *Add money coming in*, since the pace
/// card above already says what was spent. One TalkBack node, the answer first.
class SpendsSplitCard extends StatelessWidget {
  const SpendsSplitCard({super.key, required this.split, required this.isRunning, required this.cycleLabel, required this.isWeekly, this.onAddIncome});

  final MoneySplit split;

  /// The cycle holds today: "not spent yet" rather than "left over".
  final bool isRunning;

  /// The cycle as the switcher names it, for the no-income title.
  final String cycleLabel;
  final bool isWeekly;

  /// Opens Settings at *Money coming in*; without it the chip is left out.
  final VoidCallback? onAddIncome;

  static const double _barHeight = 28;
  static const double _swatch = 14;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    return SpendsCard(child: split.hasIncome ? _split(context, strings) : _noIncome(context, strings));
  }

  Widget _split(BuildContext context, AppLocalizations strings) {
    final TextTheme type = Theme.of(context).textTheme;
    final AmountWriter shown = MonthStoryCopy.shown(context.money);
    final String? savedLine = _savedLine(strings, shown);
    return Semantics(
      container: true,
      label: _spoken(strings, MonthStoryCopy.spoken(strings, context.money)),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(strings.spendsSplitTitle(shown(split.income)), style: type.titleMedium),
          const SizedBox(height: HisaabSpacing.s),
          Text(_answer(strings, shown), style: type.displaySmall),
          if (savedLine != null) Text(savedLine, style: type.bodyMedium?.copyWith(color: context.colors.ink2)),
          const SizedBox(height: HisaabSpacing.l),
          SizedBox(height: _barHeight, child: CustomPaint(painter: SplitBarPainter(amounts: _amounts, colours: _colours(context)))),
          const SizedBox(height: HisaabSpacing.m),
          if (!split.bills.isZero) _key(context, strings.storyKeyBills, split.bills, context.colors.ink),
          _key(context, strings.storyKeyEveryday, split.everyday + split.notLogged, context.colors.fillSoft),
          const SizedBox(height: HisaabSpacing.xs),
          Text(_note(strings, shown), style: type.bodySmall?.copyWith(color: context.colors.ink2)),
        ],
      ),
    );
  }

  Widget _noIncome(BuildContext context, AppLocalizations strings) {
    final TextTheme type = Theme.of(context).textTheme;
    final VoidCallback? add = onAddIncome;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(strings.spendsSplitNoIncomeTitle(isRunning ? 'now' : 'done', isWeekly ? 'week' : 'month', cycleLabel), style: type.titleMedium),
        const SizedBox(height: HisaabSpacing.xs),
        Text(strings.spendsSplitNoIncomeBody, style: type.bodyMedium?.copyWith(color: context.colors.ink2)),
        if (add != null) ...<Widget>[
          const SizedBox(height: HisaabSpacing.m),
          HisaabChip(key: const ValueKey<String>('add-money-in'), label: strings.spendsSplitNoIncomeAction, onPressed: add),
        ],
      ],
    );
  }

  String _answer(AppLocalizations strings, AmountWriter amount) {
    final Money left = split.left;
    if (left.isNegative) {
      return strings.storyMoreThanCameIn(amount(Money.zero - left));
    }
    if (left.isZero) {
      return isRunning ? strings.spendsSplitNoneNow : strings.spendsSplitNoneDone;
    }
    return isRunning ? strings.spendsSplitNotSpentYet(amount(left)) : strings.storyLeftOver(amount(left));
  }

  String? _savedLine(AppLocalizations strings, AmountWriter amount) {
    if (split.saved.isZero) {
      return null;
    }
    return split.left.isNegative ? strings.spendsSplitIncludesSaved(amount(split.saved)) : strings.spendsSplitSaved(amount(split.saved));
  }

  String _note(AppLocalizations strings, AmountWriter amount) =>
      split.notLogged.isZero ? strings.spendsSplitNote : strings.spendsSplitNoteNotLogged(amount(split.notLogged));

  String _spoken(AppLocalizations strings, AmountWriter amount) => <String>[
        strings.spendsSplitSpokenOf(_answer(strings, amount).replaceAll(RegExp(r'\.$'), ''), amount(split.income)),
        if (!split.bills.isZero) strings.spendsSpokenPart(strings.storyKeyBills, amount(split.bills)),
        if (!split.saved.isZero) strings.spendsSpokenPart(strings.storyKeySaved, amount(split.saved)),
        strings.spendsSpokenPart(strings.storyKeyEveryday, amount(split.everyday + split.notLogged)),
      ].join(' ');

  SplitAmounts get _amounts => (
        bills: split.bills.amountMinor,
        saved: split.saved.amountMinor,
        everyday: (split.everyday + split.notLogged).amountMinor,
        income: split.income.amountMinor,
      );

  static SplitColours _colours(BuildContext context) =>
      (ink: context.colors.ink, ink2: context.colors.ink2, soft: context.colors.fillSoft, sunk: context.colors.sunk, gap: context.colors.surface);

  Widget _key(BuildContext context, String label, Money amount, Color swatch) {
    final TextTheme type = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: HisaabSpacing.xs),
      child: Row(
        children: <Widget>[
          Container(
            width: _swatch,
            height: _swatch * 0.8,
            decoration: BoxDecoration(color: swatch, borderRadius: BorderRadius.circular(HisaabRadii.block / 2)),
          ),
          const SizedBox(width: HisaabSpacing.s),
          Expanded(child: Text(label, style: type.bodyMedium?.copyWith(color: context.colors.ink2))),
          Text(context.money.format(amount), style: type.titleSmall?.copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}
