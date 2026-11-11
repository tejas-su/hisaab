import 'package:material_ui/material_ui.dart';

import '../../design/hisaab_type.dart';
import '../../extensions/build_context_extensions.dart';
import 'week_bars_painter.dart';

/// The weekday letters under [WeekBars], each centred on its column; today's is Semibold
/// (SPEC BR-6a). They take the place of the Day Blocks' captions.
class WeekLetters extends StatelessWidget {
  const WeekLetters({super.key, required this.letters, required this.todayIndex});

  /// Seven narrow weekday names, Monday first.
  final List<String> letters;
  final int todayIndex;

  @override
  Widget build(BuildContext context) {
    final TextStyle? caption = HisaabType.regular(Theme.of(context).textTheme.labelSmall)?.copyWith(color: context.colors.displayInk2);
    return ExcludeSemantics(
      child: Row(
        children: <Widget>[
          for (int i = 0; i < letters.length; i++) ...<Widget>[
            if (i > 0) const SizedBox(width: WeekBarsPainter.gap),
            Expanded(
              child: Text(
                letters[i],
                key: ValueKey<int>(i),
                textAlign: TextAlign.center,
                style: i == todayIndex ? HisaabType.emphasized(caption)?.copyWith(color: context.colors.displayInk) : caption,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
