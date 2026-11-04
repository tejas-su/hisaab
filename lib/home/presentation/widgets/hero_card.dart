import '../../../core/design/hisaab_type.dart';

import 'package:flutter/material.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_motion.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/day_blocks/day_blocks.dart';
import '../../../core/widgets/display_card.dart';
import '../../../core/widgets/week_bars/week_bars.dart';
import '../../../core/widgets/week_bars/week_letters.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../day_blocks_mapper.dart';
import '../hero_copy.dart';
import '../week_bars_mapper.dart';
import 'hero_press.dart';
import 'hero_sheen.dart';
import 'range_line.dart';

/// The hero: safe to spend today, the Day Blocks with the payday flag, and the range line
/// (SPEC FR-HO-2). TalkBack reads it as one sentence (FR-HO-7). Today's block fills in each
/// time the card appears and on each new day (D91).
///
/// It is the only raised card on Home, etched like a payment card, and a band of light crosses
/// it once as it appears and on each new day; it sinks a little under a finger (D106).
///
/// [week] shows *This week*: its number, the weekday bars in place of the blocks (the card grows
/// 48dp for them), and the week in words (BR-6a). Tapping the card calls [onTap] to flip it.
/// [assemble] slides the blocks in once, after onboarding.
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.summary, required this.onTap, this.week = false, this.assemble = false});

  final CycleSummary summary;
  final VoidCallback onTap;
  final bool week;
  final bool assemble;

  /// Width of the payday flag column and its gap from the blocks (UI_DESIGN §5.2 mockup).
  static const double _flagColumnWidth = 44;
  static const double _flagGap = 10;
  static const double _captionGap = 6;

  /// *This week*'s bars get room the Day Blocks' 40dp row can't give, so the card grows by 48dp
  /// only after a tap (case study 15, W2).
  static const double _weekBarsHeight = 88;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final HeroCopy copy = HeroCopy.of(summary, strings: strings, money: context.money, week: week);
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle? caption = HisaabType.regular(text.labelSmall)?.copyWith(color: context.colors.displayInk2);
    final String? overText = copy.overText.toNullable();
    final bool reduceMotion = HisaabMotion.reduceMotion(context);
    return Semantics(
      container: true,
      label: copy.spoken,
      onTap: onTap,
      onTapHint: week ? strings.showToday : strings.showThisWeek,
      excludeSemantics: true,
      child: HeroPress(
        onTap: onTap,
        child: HeroSheen(
          // why: a new day plays the sheen again, with today's block filling in (D91).
          key: ValueKey<CalendarDate>(summary.today),
          child: DisplayCard(
            raised: true,
            etched: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
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
                const SizedBox(height: HisaabSpacing.xl),
                _resizing(
                  reduceMotion: reduceMotion,
                  child: AnimatedSwitcher(
                    duration: HisaabMotion.reducedCrossfade,
                    layoutBuilder: _stackFromTop,
                    child: week ? _weekRows(context, copy, caption) : _dayRows(context, copy, caption),
                  ),
                ),
                const SizedBox(height: HisaabSpacing.gutter),
                // why: the subtlest line, so the range line reads as part of the card, not a new section.
                Divider(color: context.colors.displayEtch, height: 1),
                const SizedBox(height: HisaabSpacing.l),
                RangeLine(words: copy.range, calm: copy.calm),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dayRows(BuildContext context, HeroCopy copy, TextStyle? caption) => Column(
        key: const ValueKey<String>('hero-today-rows'),
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: DayBlocks(
                  // why: a new day gets a fresh block that fills in again (D91).
                  key: ValueKey<CalendarDate>(summary.today),
                  data: DayBlocksMapper.of(summary),
                  semanticLabel: copy.laterCaption,
                  assemble: assemble,
                  fillIn: true,
                ),
              ),
              const SizedBox(width: _flagGap),
              _flag(context, copy, caption),
            ],
          ),
          const SizedBox(height: _captionGap),
          Row(
            children: <Widget>[
              Text(AppLocalizations.of(context).todayTitle, style: caption),
              const SizedBox(width: HisaabSpacing.s),
              // why: ends exactly under the last block, past which sits the flag column.
              Expanded(
                child: Text(copy.laterCaption, style: caption, textAlign: TextAlign.end),
              ),
              const SizedBox(width: _flagGap + _flagColumnWidth),
            ],
          ),
        ],
      );

  /// *This week*: the weekday bars where the blocks were, and their letters where the captions
  /// were; the payday flag stays (BR-6a).
  Widget _weekRows(BuildContext context, HeroCopy copy, TextStyle? caption) => Column(
        key: const ValueKey<String>('hero-week-rows'),
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(child: WeekBars(data: WeekBarsMapper.of(summary), height: _weekBarsHeight)),
              const SizedBox(width: _flagGap),
              _flag(context, copy, caption),
            ],
          ),
          const SizedBox(height: _captionGap),
          Row(
            children: <Widget>[
              Expanded(
                child: WeekLetters(
                  letters: WeekBarsMapper.letters(context.money.locale),
                  todayIndex: summary.today.weekday - DateTime.monday,
                ),
              ),
              const SizedBox(width: _flagGap + _flagColumnWidth),
            ],
          ),
        ],
      );

  Widget _flag(BuildContext context, HeroCopy copy, TextStyle? caption) => SizedBox(
        width: _flagColumnWidth,
        child: Column(
          children: <Widget>[
            AppIcon(AppIcons.payday, size: 18, color: context.colors.displayInk),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(copy.payday, style: HisaabType.emphasized(caption)),
            ),
          ],
        ),
      );

  // why: with reduced motion the card takes its new size at once; a zero-length AnimatedSize
  // would trip Flutter's relayout assertion, so it is left out.
  static Widget _resizing({required bool reduceMotion, required Widget child}) => reduceMotion
      ? child
      : AnimatedSize(
          duration: HisaabMotion.resize,
          curve: HisaabMotion.easeOut,
          alignment: AlignmentDirectional.topStart,
          child: child,
        );

  // why: the outgoing and incoming rows overlap from the top while the card resizes, so the
  // bars rise where the blocks were rather than from the middle.
  static Widget _stackFromTop(Widget? current, List<Widget> previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: <Widget>[...previous, ?current],
      );
}
