import '../../../core/design/hisaab_type.dart';
import 'package:flutter/material.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/day_blocks/day_blocks.dart';
import '../../../core/widgets/display_card.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../day_blocks_mapper.dart';
import '../hero_copy.dart';
import 'range_line.dart';

/// The hero: safe to spend today, the Day Blocks with the payday flag, and the range line
/// (SPEC FR-HO-2). TalkBack reads it as one sentence (FR-HO-7).
///
/// [week] shows *This week*'s number instead of today's; tapping the card calls [onTap] to flip
/// it. [assemble] slides the blocks in once, after onboarding.
class HeroCard extends StatelessWidget {
  const HeroCard({super.key, required this.summary, required this.onTap, this.week = false, this.assemble = false});

  final CycleSummary summary;
  final VoidCallback onTap;
  final bool week;
  final bool assemble;

  /// Width of the payday flag column and its gap from the blocks (UI_DESIGN §5.2 mockup).
  static const double _flagColumnWidth = 44;
  static const double _flagGap = 10;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final HeroCopy copy = HeroCopy.of(summary, strings: strings, money: context.money, week: week);
    final TextTheme text = Theme.of(context).textTheme;
    final TextStyle? caption = HisaabType.regular(text.labelSmall)?.copyWith(color: context.colors.displayInk2);
    final String? overText = copy.overText.toNullable();
    return Semantics(
      container: true,
      label: copy.spoken,
      onTap: onTap,
      onTapHint: week ? strings.showToday : strings.showThisWeek,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DisplayCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(copy.title, style: text.bodyMedium?.copyWith(color: context.colors.displayInk2)),
              const SizedBox(height: HisaabSpacing.xs),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: HisaabSpacing.m,
                children: <Widget>[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: AmountText(
                      copy.heroAmount,
                      style: text.displayLarge?.copyWith(color: copy.muted ? context.colors.displayInk2 : context.colors.displayInk),
                    ),
                  ),
                  if (overText != null)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(bottom: 10),
                      child: Text(overText, style: text.titleMedium?.copyWith(color: context.colors.displayInk)),
                    ),
                ],
              ),
              const SizedBox(height: HisaabSpacing.l),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Expanded(
                    child: DayBlocks(
                      data: DayBlocksMapper.of(summary),
                      semanticLabel: copy.laterCaption,
                      assemble: assemble,
                    ),
                  ),
                  const SizedBox(width: _flagGap),
                  SizedBox(
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
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: <Widget>[
                  Text(strings.todayTitle, style: caption),
                  const SizedBox(width: HisaabSpacing.s),
                  // why: ends exactly under the last block, past which sits the flag column.
                  Expanded(child: Text(copy.laterCaption, style: caption, textAlign: TextAlign.end)),
                  const SizedBox(width: _flagGap + _flagColumnWidth),
                ],
              ),
              const SizedBox(height: 14),
              Divider(color: context.colors.hairline, height: 1),
              const SizedBox(height: HisaabSpacing.m),
              RangeLine(words: copy.range, calm: copy.calm),
            ],
          ),
        ),
      ),
    );
  }
}
