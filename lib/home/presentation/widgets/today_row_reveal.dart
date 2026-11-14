import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_motion.dart';

/// Holds a new *Not logged* row back until the hero has rolled, then grows it into the Today list, so
/// a figure is read before the list shifts under it (SPEC FR-FX-5 AC-2, C9). Any other row is shown
/// as it is.
///
/// [delayed] is set only when the row first appears; it never repeats for a row already shown.
/// Reduced motion gives the row its height at once and a 150 ms fade, with no delay (E13).
class TodayRowReveal extends StatefulWidget {
  const TodayRowReveal({super.key, required this.delayed, required this.child});

  /// Whether to wait for the hero before growing in.
  final bool delayed;
  final Widget child;

  /// How long the row waits: the hero's own roll, so the list moves after the number has settled.
  static const Duration delay = HisaabMotion.numberRoll;

  @override
  State<TodayRowReveal> createState() => _TodayRowRevealState();
}

class _TodayRowRevealState extends State<TodayRowReveal> {
  Timer? _timer;
  late bool _shown = !widget.delayed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_shown && _timer == null && !HisaabMotion.reduceMotion(context)) {
      _timer = Timer(TodayRowReveal.delay, () {
        if (mounted) {
          setState(() => _shown = true);
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduced = HisaabMotion.reduceMotion(context);
    final bool visible = _shown || reduced;
    return AnimatedSize(
      duration: reduced ? Duration.zero : HisaabMotion.resize,
      curve: HisaabMotion.easeOut,
      alignment: Alignment.topCenter,
      child: visible
          ? AnimatedOpacity(
              opacity: 1,
              duration: HisaabMotion.reducedCrossfade,
              child: widget.child,
            )
          : const SizedBox(width: double.infinity),
    );
  }
}
