import 'package:fpdart/fpdart.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/month_story.dart';
import '../month_story_copy.dart';
import 'day_bars.dart';
import 'story_page_frame.dart';

/// Page 4, your days (SPEC BR-20, D194): the biggest day, the day bars, the quiet days and the
/// weekday line. Bills are left out, and the key says so.
class StoryDaysPage extends StatelessWidget {
  const StoryDaysPage({super.key, required this.story, required this.days, required this.categories});

  final MonthStory story;
  final StoryDays days;

  /// Names the biggest day's category when its entry has no note.
  final Map<int, Category> categories;

  static const double _barsHeight = 150;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    final AmountWriter shown = MonthStoryCopy.shown(context.money);
    final AmountWriter spoken = MonthStoryCopy.spoken(strings, context.money);
    final String peakDay = MonthStoryCopy.day(story.cycle.start.addDays(days.peakIndex), locale);
    final String what = days.peakNote.getOrElse(() => categories[days.peakCategoryId]?.labelIn(strings) ?? '');
    final String quiet = strings.storyQuietDays(days.quietDays);
    final Option<String> weekday = days.weekday.map((StoryWeekday w) => MonthStoryCopy.weekday(w, strings, shown));
    return StoryPageFrame(
      eyebrow: strings.storyDaysEyebrow,
      big: strings.storyBiggestDay(peakDay),
      bigIsAmount: false,
      spoken: <String>[
        '${strings.storyBiggestDay(peakDay)}. ${strings.storyBiggestDayDetail(spoken(days.peak), what)}.',
        quiet,
        ...days.weekday.match(() => const <String>[], (StoryWeekday w) => <String>[MonthStoryCopy.weekday(w, strings, spoken)]),
      ].join(' '),
      children: <Widget>[
        StoryPageFrame.line(context, strings.storyBiggestDayDetail(shown(days.peak), what), quiet: true),
        const SizedBox(height: HisaabSpacing.xl),
        DayBars(
          data: MonthStoryCopy.bars(days, story.cycle.start),
          height: _barsHeight,
          peakIndex: days.peakIndex,
          dates: (
            MonthStoryCopy.shortDate(story.cycle.start, locale),
            MonthStoryCopy.shortDate(story.cycle.start.addDays(days.peakIndex), locale),
            MonthStoryCopy.shortDate(story.cycle.end, locale),
          ),
        ),
        const SizedBox(height: HisaabSpacing.l),
        StoryPageFrame.line(context, quiet),
        ...weekday.match(() => const <Widget>[], (String line) => <Widget>[StoryPageFrame.line(context, line)]),
        const SizedBox(height: HisaabSpacing.s),
        ExcludeSemantics(child: Text(_key(strings, shown), style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.ink2))),
      ],
    );
  }

  String _key(AppLocalizations strings, AmountWriter shown) =>
      days.share.match(() => strings.storyDaysKeyNoShare, (Money share) => strings.storyDaysKeyShare(shown(share)));
}
