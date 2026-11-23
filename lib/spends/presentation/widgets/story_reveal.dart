import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_motion.dart';

/// A month story page's lines in a stretched column, rising into place one after another when the
/// page opens: each fades in and slides up a quarter of its own height, [HisaabMotion.storyStagger]
/// after the one before (D210).
///
/// One controller drives every line and is disposed with the page. With reduced motion the lines
/// are in place from the first frame.
class StoryReveal extends StatefulWidget {
  const StoryReveal({super.key, required this.children});

  final List<Widget> children;

  /// How far each line starts below its place, as a fraction of its own height.
  static const double rise = 0.25;

  @override
  State<StoryReveal> createState() => _StoryRevealState();
}

class _StoryRevealState extends State<StoryReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(vsync: this, duration: _total);

  Duration get _total => HisaabMotion.storyReveal + HisaabMotion.storyStagger * (widget.children.length - 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reveal.status != AnimationStatus.dismissed) {
      return;
    }
    if (HisaabMotion.reduceMotion(context)) {
      _reveal.value = 1;
      return;
    }
    _reveal.forward();
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int i = 0; i < widget.children.length; i++) _line(i),
        ],
      );

  Widget _line(int index) {
    final double total = _total.inMilliseconds.toDouble();
    final double start = HisaabMotion.storyStagger.inMilliseconds * index / total;
    final double end = start + HisaabMotion.storyReveal.inMilliseconds / total;
    // why: drive() adds no listener of its own, unlike a CurvedAnimation, so a rebuild leaks nothing.
    final Animation<double> shown = _reveal.drive(CurveTween(curve: Interval(start, end, curve: HisaabMotion.easeOut)));
    return FadeTransition(
      opacity: shown,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, StoryReveal.rise), end: Offset.zero).animate(shown),
        child: widget.children[index],
      ),
    );
  }
}
