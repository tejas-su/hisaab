import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/design/hisaab_theme.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/month_story.dart';
import '../month_story_copy.dart';
import 'day_bars.dart';

/// The month story card, directly below the Ask AI card on a finished cycle (SPEC FR-SP-7 AC-1):
/// *Your month*, page 2's headline, a small day-bars preview and *See the story*, on the story's
/// dark surface in either theme. One button for TalkBack.
class MonthStoryCard extends StatelessWidget {
  const MonthStoryCard({super.key, required this.story, required this.cycleLabel, required this.onPressed});

  final MonthStory story;
  final String cycleLabel;
  final VoidCallback onPressed;

  static const double _previewHeight = 36;
  static const double _actionHeight = 36;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String spoken = strings.storyCardSpoken(cycleLabel, MonthStoryCopy.headline(story, strings, MonthStoryCopy.spoken(strings, context.money)));
    return Theme(
      data: HisaabTheme.dark(),
      child: Builder(
        builder: (BuildContext context) => Pressable(
          semanticLabel: spoken,
          onPressed: onPressed,
          focusRadius: HisaabRadii.card,
          builder: (BuildContext context, bool pressed) => Container(
            key: const ValueKey<String>('month-story-card-surface'),
            padding: const EdgeInsetsDirectional.all(HisaabSpacing.gutter),
            decoration: ShapeDecoration(
              color: pressed ? context.colors.sunk : context.colors.surface,
              shape: HisaabShapes.squircle(HisaabRadii.card),
            ),
            child: _content(context, strings),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context, AppLocalizations strings) {
    final TextTheme type = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(strings.storyCardEyebrow, style: type.labelMedium?.copyWith(color: context.colors.ink2)),
        const SizedBox(height: HisaabSpacing.xs),
        Text(MonthStoryCopy.headline(story, strings, MonthStoryCopy.shown(context.money)), style: type.displaySmall),
        ...story.days.match(
          () => const <Widget>[],
          (StoryDays days) => <Widget>[
            const SizedBox(height: HisaabSpacing.m),
            DayBars(data: MonthStoryCopy.bars(days, story.cycle.start), height: _previewHeight),
          ],
        ),
        const SizedBox(height: HisaabSpacing.m),
        Container(
          height: _actionHeight,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.l),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            shape: HisaabShapes.squircle(_actionHeight / 2, side: BorderSide(color: context.colors.hairline, width: 1.5)),
          ),
          child: Text(strings.storyCardAction, style: type.labelLarge),
        ),
      ],
    );
  }
}
