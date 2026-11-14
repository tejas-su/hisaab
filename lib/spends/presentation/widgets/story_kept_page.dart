import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/month_story.dart';
import '../month_story_copy.dart';
import 'story_page_frame.dart';
import 'story_split_bar.dart';

/// Page 2, what you kept (SPEC BR-20): the spend, the split bar against what came in, and what was
/// left over or went past it. With nothing coming in, the spend alone (E118).
class StoryKeptPage extends StatelessWidget {
  const StoryKeptPage({super.key, required this.story});

  final MonthStory story;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final AmountWriter shown = MonthStoryCopy.shown(context.money);
    final AmountWriter spoken = MonthStoryCopy.spoken(strings, context.money);
    return StoryPageFrame(
      eyebrow: strings.storyKeptEyebrow,
      big: shown(story.spent),
      spoken: _sentences(strings, spoken).join(' '),
      children: story.hasIncome
          ? <Widget>[
              StoryPageFrame.line(context, strings.storyKeptOf(shown(story.income)), quiet: true),
              const SizedBox(height: HisaabSpacing.xl),
              StorySplitBar(story: story),
              const SizedBox(height: HisaabSpacing.l),
              Text(MonthStoryCopy.headline(story, strings, shown), style: Theme.of(context).textTheme.displaySmall),
              if (!story.saved.isZero) StoryPageFrame.line(context, strings.storySavedLine(shown(story.saved)), quiet: true),
            ]
          : const <Widget>[],
    );
  }

  List<String> _sentences(AppLocalizations strings, AmountWriter spoken) => <String>[
        '${strings.storyKeptEyebrow} ${spoken(story.spent)}${story.hasIncome ? ' ${strings.storyKeptOf(spoken(story.income))}' : ''}.',
        if (story.hasIncome) '${MonthStoryCopy.headline(story, strings, spoken)}${story.saved.isZero ? '' : ', ${strings.storySavedLine(spoken(story.saved))}'}.',
      ];
}
