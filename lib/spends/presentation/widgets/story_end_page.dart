import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/month_story.dart';
import '../month_story_copy.dart';
import 'story_page_frame.dart';

/// Page 6, the end (SPEC BR-20): spent, saved and left over (or past what came in) once more. Its
/// two actions sit below the page, outside the tap zones (FR-SP-7 AC-8).
class StoryEndPage extends StatelessWidget {
  const StoryEndPage({super.key, required this.story, required this.cycleLabel});

  final MonthStory story;
  final String cycleLabel;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final List<(String, Money)> rows = _rows(strings);
    final AmountWriter spoken = MonthStoryCopy.spoken(strings, context.money);
    return StoryPageFrame(
      eyebrow: strings.storyEndEyebrow(cycleLabel),
      big: cycleLabel,
      spoken: <String>[
        '${strings.storyEndEyebrow(cycleLabel)}.',
        for (final (String label, Money amount) in rows) '$label ${spoken(amount)}.',
      ].join(' '),
      children: <Widget>[for (final (String label, Money amount) in rows) _row(context, label, amount)],
    );
  }

  List<(String, Money)> _rows(AppLocalizations strings) => <(String, Money)>[
        (strings.storyKeySpent, story.spent),
        if (!story.saved.isZero) (strings.storyKeySaved, story.saved),
        if (story.hasIncome)
          story.left.isNegative ? (strings.storyKeyMoreThanCameIn, Money.zero - story.left) : (strings.storyKeyLeftOver, story.left),
      ];

  Widget _row(BuildContext context, String label, Money amount) {
    final TextTheme type = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: HisaabSpacing.s),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: type.bodyLarge?.copyWith(color: context.colors.ink2))),
          Text(context.money.format(amount), style: type.titleLarge?.copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}
