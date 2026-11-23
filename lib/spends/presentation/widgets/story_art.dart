import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_motion.dart';
import '../../../core/extensions/build_context_extensions.dart';
import 'story_art_painter.dart';
import 'story_grain_painter.dart';
import 'story_motif.dart';

/// Decoration behind a month story page or the story card: one [StoryMotif] over a still grain,
/// in `hairline` line work only, so no hue is added (D210).
///
/// When [animate] is set, the art settles in once (from slightly larger, turned and faded), then
/// drifts slowly for the rest of [HisaabMotion.storyDrift] and stops. The motif is painted once
/// into its own layer and only that layer moves, so the drift never repaints it. With reduced
/// motion, or with [animate] off, it is still from the first frame. It fills its parent, is never
/// announced and never takes a touch.
class StoryArt extends StatefulWidget {
  const StoryArt({super.key, required this.motif, this.animate = true});

  final StoryMotif motif;
  final bool animate;

  /// Finds the painted motif, for tests.
  static const Key paintKey = ValueKey<String>('story-art-paint');

  /// Finds the fade the art settles in with, for tests.
  static const Key fadeKey = ValueKey<String>('story-art-fade');

  @override
  State<StoryArt> createState() => _StoryArtState();
}

class _StoryArtState extends State<StoryArt> with SingleTickerProviderStateMixin {
  late final AnimationController _course = AnimationController(vsync: this, duration: HisaabMotion.storyDrift);

  // why: drive() adds no status listener of its own, unlike a CurvedAnimation, so nothing needs disposing.
  late final Animation<double> _entry = _course.drive(
    CurveTween(curve: Interval(0, HisaabMotion.storyArt.inMilliseconds / HisaabMotion.storyDrift.inMilliseconds, curve: HisaabMotion.easeOut)),
  );

  late final Animation<double> _drift = _course.drive(CurveTween(curve: HisaabMotion.drift));

  // why: a small turn and grow on entry is enough to feel alive without pulling the eye off the words.
  static const double _startScale = 1.12;
  static const double _startTurn = 0.08;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_course.status != AnimationStatus.dismissed) {
      return;
    }
    if (!widget.animate || HisaabMotion.reduceMotion(context)) {
      _course.value = 1;
      return;
    }
    _course.forward();
  }

  @override
  void dispose() {
    _course.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color line = context.colors.hairline;
    final TextDirection direction = Directionality.of(context);
    // why: its own layer, painted once; the drift below only moves the layer.
    final Widget motif = RepaintBoundary(
      child: CustomPaint(
        key: StoryArt.paintKey,
        size: Size.infinite,
        painter: StoryArtPainter(motif: widget.motif, color: line, textDirection: direction),
      ),
    );
    return IgnorePointer(
      child: ExcludeSemantics(
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            RepaintBoundary(child: CustomPaint(painter: StoryGrainPainter(color: line))),
            FadeTransition(
              key: StoryArt.fadeKey,
              opacity: _entry,
              child: AnimatedBuilder(animation: _course, child: motif, builder: (BuildContext context, Widget? child) => _moved(direction, child)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _moved(TextDirection direction, Widget? child) {
    final double settling = 1 - _entry.value;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.rotationZ(settling * _startTurn)..scaleByDouble(1 + (_startScale - 1) * settling, 1 + (_startScale - 1) * settling, 1, 1),
      child: Transform(alignment: widget.motif.origin, transform: widget.motif.driftAt(_drift.value, direction), child: child),
    );
  }
}
