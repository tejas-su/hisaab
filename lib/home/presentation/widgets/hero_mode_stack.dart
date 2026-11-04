import 'package:flutter/widgets.dart';

import '../../../core/design/hisaab_motion.dart';

/// Lays out the hero's *Today* and *This week* versions of one part in the same cell and shows
/// one of them, so the card takes the taller and never resizes on a tap (SPEC BR-6, D114).
///
/// The two crossfade in 150ms; the hidden one takes no taps.
class HeroModeStack extends StatelessWidget {
  const HeroModeStack({super.key, required this.today, required this.week, required this.showWeek});

  final Widget today;
  final Widget week;
  final bool showWeek;

  @override
  Widget build(BuildContext context) => Stack(
        children: <Widget>[_layer(today, shown: !showWeek), _layer(week, shown: showWeek)],
      );

  static Widget _layer(Widget child, {required bool shown}) => IgnorePointer(
        ignoring: !shown,
        child: AnimatedOpacity(opacity: shown ? 1 : 0, duration: HisaabMotion.reducedCrossfade, child: child),
      );
}
