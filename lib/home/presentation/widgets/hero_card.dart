import 'package:flutter/material.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/days_rail/days_rail.dart';
import '../../../core/widgets/display_card.dart';
import '../../../core/widgets/week_bars/week_bars.dart';
import '../../../core/widgets/week_bars/week_letters.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../days_rail_mapper.dart';
import '../hero_copy.dart';
import '../week_bars_mapper.dart';
import 'hero_mode_stack.dart';
import 'hero_press.dart';
import 'hero_sheen.dart';
import 'hero_today_rows.dart';
import 'range_line.dart';

/// The hero: safe to spend today, today's bar, the days rail with the payday flag, and the range
/// line (SPEC FR-HO-2, BR-6). TalkBack reads it as one sentence (FR-HO-7). Today's bar fills in
/// each time the card appears and on each new day (D91).
///
/// It is the only raised card on Home, etched like a payment card, and a band of light crosses
/// it once as it appears and on each new day; it sinks a little under a finger (D106).
///
/// [week] shows *This week*: its number, the weekday bars in place of today's bar, and the week
/// in words (BR-6a). Both are laid out at once, so the card keeps one height (D114). Tapping the
/// card calls [onTap] to flip it. [spends] are today's *Spent* entries, oldest first, and
/// [categories] name their bites. [assemble] brings the rail's dots in once, after onboarding.
class HeroCard extends StatelessWidget {
  const HeroCard({
    super.key,
    required this.summary,
    required this.onTap,
    this.spends = const <Entry>[],
    this.categories = const <int, Category>{},
    this.week = false,
    this.assemble = false,
  });

  final CycleSummary summary;
  final VoidCallback onTap;
  final List<Entry> spends;
  final Map<int, Category> categories;
  final bool week;
  final bool assemble;

  static const double _captionGap = 6;
  static const double _weekBarsHeight = 64;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    HeroCopy copyFor({required bool week}) => HeroCopy.of(summary, strings: strings, money: context.money, week: week);
    final HeroCopy todayCopy = copyFor(week: false);
    final HeroCopy weekCopy = copyFor(week: true);
    final HeroCopy copy = week ? weekCopy : todayCopy;
    return Semantics(
      container: true,
      label: copy.spoken,
      onTap: onTap,
      onTapHint: week ? strings.showToday : strings.showThisWeek,
      excludeSemantics: true,
      child: HeroPress(
        onTap: onTap,
        child: HeroSheen(
          // why: a new day plays the sheen again, with today's bar filling in (D91).
          key: ValueKey<CalendarDate>(summary.today),
          child: DisplayCard(
            raised: true,
            etched: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ..._headline(context, copy),
                const SizedBox(height: HisaabSpacing.xl),
                HeroModeStack(
                  showWeek: week,
                  today: HeroTodayRows(key: const ValueKey<String>('hero-today-rows'), summary: summary, spends: spends, categories: categories),
                  week: _weekRows(context),
                ),
                const SizedBox(height: HisaabSpacing.m),
                DaysRail(
                  data: DaysRailMapper.of(summary),
                  todayCaption: strings.todayTitle,
                  laterCaption: todayCopy.laterCaption,
                  payday: copy.payday,
                  assemble: assemble,
                ),
                const SizedBox(height: HisaabSpacing.gutter),
                // why: the subtlest line, so the range line reads as part of the card, not a new section.
                Divider(color: context.colors.displayEtch, height: 1),
                const SizedBox(height: HisaabSpacing.l),
                HeroModeStack(
                  showWeek: week,
                  today: RangeLine(words: todayCopy.range, calm: todayCopy.calm),
                  week: RangeLine(words: weekCopy.range, calm: weekCopy.calm),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _headline(BuildContext context, HeroCopy copy) {
    final TextTheme text = Theme.of(context).textTheme;
    final String? overText = copy.overText.toNullable();
    return <Widget>[
      Text(copy.title, style: text.bodyMedium?.copyWith(color: context.colors.displayInk2)),
      const SizedBox(height: HisaabSpacing.s),
      Wrap(
        crossAxisAlignment: WrapCrossAlignment.end,
        spacing: HisaabSpacing.m,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            // why: the rolling digits repaint on their own layer, not the card's shadow and text.
            child: RepaintBoundary(
              child: AmountText(
                copy.heroAmount,
                style: text.displayLarge?.copyWith(color: copy.muted ? context.colors.displayInk2 : context.colors.displayInk),
              ),
            ),
          ),
          if (overText != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 10),
              child: Text(overText, style: text.titleMedium?.copyWith(color: context.colors.displayInk)),
            ),
        ],
      ),
    ];
  }

  /// *This week*: the weekday bars at the card's full width with their letters under them (BR-6a).
  Widget _weekRows(BuildContext context) => Column(
        key: const ValueKey<String>('hero-week-rows'),
        children: <Widget>[
          // why: a new key each time This week is shown, so its bars rise again (D111).
          WeekBars(key: ValueKey<bool>(week), data: WeekBarsMapper.of(summary), height: _weekBarsHeight),
          const SizedBox(height: _captionGap),
          WeekLetters(
            letters: WeekBarsMapper.letters(context.money.locale),
            todayIndex: summary.today.weekday - DateTime.monday,
          ),
        ],
      );
}
