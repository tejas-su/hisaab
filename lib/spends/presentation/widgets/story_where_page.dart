import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/category_spend.dart';
import '../../domain/entities/month_story.dart';
import '../month_story_copy.dart';
import 'story_page_frame.dart';

/// Page 3, where it went (SPEC BR-20): every row of *Where it went*, biggest first, with ₹ and %.
class StoryWherePage extends StatelessWidget {
  const StoryWherePage({super.key, required this.story});

  final MonthStory story;

  static const double _barHeight = 8;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AmountWriter spoken = MonthStoryCopy.spoken(strings, context.money);
    final String top = story.rows.first.category.labelIn(strings);
    return StoryPageFrame(
      eyebrow: strings.storyWhereEyebrow,
      big: strings.storyMostWent(top),
      bigIsAmount: false,
      spoken: <String>[
        '${strings.storyMostWent(top)}.',
        for (final CategorySpend row in story.rows) '${row.category.labelIn(strings)}, ${spoken(row.spent)}, ${row.percent}%.',
      ].join(' '),
      children: <Widget>[for (final CategorySpend row in story.rows) _row(context, strings, row)],
    );
  }

  Widget _row(BuildContext context, AppLocalizations strings, CategorySpend row) {
    final TextTheme type = Theme.of(context).textTheme;
    final double share = row.spent.amountMinor / story.rows.first.spent.amountMinor;
    return Padding(
      key: ValueKey<int>(row.category.id),
      padding: const EdgeInsetsDirectional.only(bottom: HisaabSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(child: Text(row.category.labelIn(strings), style: type.bodyLarge)),
              Text(context.money.format(row.spent), style: type.titleMedium?.copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()])),
              const SizedBox(width: HisaabSpacing.s),
              Text('${row.percent}%', style: type.bodySmall?.copyWith(color: context.colors.ink2)),
            ],
          ),
          const SizedBox(height: HisaabSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(_barHeight / 2),
            child: SizedBox(
              height: _barHeight,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(child: ColoredBox(color: context.colors.sunk)),
                  FractionallySizedBox(widthFactor: share, heightFactor: 1, child: ColoredBox(color: context.colors.ink)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
