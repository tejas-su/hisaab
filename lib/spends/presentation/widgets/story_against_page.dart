import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/month_story.dart';
import '../month_story_copy.dart';
import 'story_page_frame.dart';

/// Page 5, against the cycle before (SPEC BR-20): the change in *Spent* and the three categories
/// that moved most, in words, never colour.
class StoryAgainstPage extends StatelessWidget {
  const StoryAgainstPage({super.key, required this.against, required this.previousLabel});

  final StoryComparison against;

  /// The cycle before, named as the switcher names it.
  final String previousLabel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AmountWriter shown = MonthStoryCopy.shown(context.money);
    final AmountWriter spoken = MonthStoryCopy.spoken(strings, context.money);
    return StoryPageFrame(
      eyebrow: strings.storyAgainstEyebrow(previousLabel),
      big: MonthStoryCopy.change(against, previousLabel, strings, shown),
      bigIsAmount: false,
      spoken: <String>[
        '${MonthStoryCopy.change(against, previousLabel, strings, spoken)}.',
        '${strings.storyPreviousSpent(previousLabel, spoken(against.previousSpent))}.',
        for (final CategoryMove move in against.moves) '${move.category.labelIn(strings)}, ${MonthStoryCopy.move(move, strings, spoken)}.',
      ].join(' '),
      children: <Widget>[
        StoryPageFrame.line(context, strings.storyPreviousSpent(previousLabel, shown(against.previousSpent)), quiet: true),
        const SizedBox(height: HisaabSpacing.xl),
        for (final (int i, CategoryMove move) in against.moves.indexed) _move(context, strings, move, first: i == 0),
      ],
    );
  }

  Widget _move(BuildContext context, AppLocalizations strings, CategoryMove move, {required bool first}) {
    final TextTheme type = Theme.of(context).textTheme;
    return Container(
      key: ValueKey<int>(move.category.id),
      padding: const EdgeInsetsDirectional.symmetric(vertical: HisaabSpacing.m),
      decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: context.colors.hairline))),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(move.category.labelIn(strings), style: type.bodyLarge)),
          Text(MonthStoryCopy.move(move, strings, MonthStoryCopy.shown(context.money)), style: type.titleMedium),
        ],
      ),
    );
  }
}
