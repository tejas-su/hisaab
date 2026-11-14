import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/month_story.dart';
import '../month_story_copy.dart';
import 'day_bars.dart';
import 'story_page_frame.dart';

/// Page 1, the month (SPEC BR-20): its name, its days and entries, and a small preview of page 4.
class StoryMonthPage extends StatelessWidget {
  const StoryMonthPage({super.key, required this.story, required this.cycleLabel});

  final MonthStory story;
  final String cycleLabel;

  static const double _previewHeight = 44;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final String span = strings.storyMonthSpan(
      MonthStoryCopy.shortDate(story.cycle.start, locale),
      MonthStoryCopy.shortDate(story.cycle.end, locale),
      story.cycle.lengthInDays,
    );
    final String entries = strings.storyMonthEntries(story.entryCount);
    return StoryPageFrame(
      eyebrow: strings.storyCardEyebrow,
      big: cycleLabel,
      spoken: '$cycleLabel. $span. $entries.',
      children: <Widget>[
        StoryPageFrame.line(context, span, quiet: true),
        StoryPageFrame.line(context, entries, quiet: true),
        ...story.days.match(
          () => const <Widget>[],
          (StoryDays days) => <Widget>[
            const SizedBox(height: HisaabSpacing.xxl),
            DayBars(data: MonthStoryCopy.bars(days, story.cycle.start), height: _previewHeight),
          ],
        ),
        const SizedBox(height: HisaabSpacing.l),
        ExcludeSemantics(
          child: Text(strings.storyTapHint, textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.ink2)),
        ),
      ],
    );
  }
}
