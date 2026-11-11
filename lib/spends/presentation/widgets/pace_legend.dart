import 'package:material_ui/material_ui.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_type.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/pace_series.dart';

/// The pace chart's key: *You*, *Steady pace* and *At this pace* when [showForecast] on one row,
/// then the verdict with its glyph, then [line], the gap and forecast in words, when given
/// (FR-SP-3, D77, D133, D135). The keys wrap, so the longer words never clip.
class PaceLegend extends StatelessWidget {
  const PaceLegend({super.key, required this.verdict, required this.showForecast, this.line});

  final PaceVerdict verdict;
  final bool showForecast;

  /// "₹7,042 under steady pace. At this pace about ₹9,300 spare."; null on a past cycle.
  final String? line;

  static const double _markWidth = 16;
  static const double _markHeight = 2.5;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final TextStyle? caption = Theme.of(context).textTheme.bodySmall;
    final bool below = verdict == PaceVerdict.belowPace;
    final String? words = line;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: HisaabSpacing.m,
          runSpacing: HisaabSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: <Widget>[
            _key(Container(width: _markWidth, height: _markHeight, color: context.colors.ink), Text(strings.paceYou, style: caption)),
            _key(_mark(_KeyDashes(context.colors.ink2, dash: 0, gap: 4)), Text(strings.paceSteady, style: caption)),
            if (showForecast)
              _key(_mark(_KeyDashes(context.colors.ink, dash: 6, gap: 5)), Text(strings.paceAtThisPace, style: caption)),
          ],
        ),
        const SizedBox(height: HisaabSpacing.s),
        _key(
          AppIcon(below ? AppIcons.onTrack : AppIcons.alert, size: 16),
          Text(below ? strings.belowPace : strings.abovePace, style: HisaabType.emphasized(caption)?.copyWith(color: context.colors.ink)),
        ),
        if (words != null) ...<Widget>[
          const SizedBox(height: HisaabSpacing.xs),
          Text(words, style: caption?.copyWith(color: context.colors.ink)),
        ],
      ],
    );
  }

  static Widget _mark(CustomPainter painter) =>
      SizedBox(width: _markWidth, height: _markHeight, child: CustomPaint(painter: painter));

  static Widget _key(Widget mark, Widget label) =>
      Row(mainAxisSize: MainAxisSize.min, children: <Widget>[mark, const SizedBox(width: 6), label]);
}

/// A legend mark of round-capped dashes; a [dash] of 0 draws the steady line's dots.
class _KeyDashes extends CustomPainter {
  const _KeyDashes(this.color, {required this.dash, required this.gap});

  final Color color;
  final double dash;
  final double gap;

  static const double _stroke = 2;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    final double y = size.height / 2;
    for (double x = 1; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(x, size.width - 1), y), paint);
    }
  }

  @override
  bool shouldRepaint(_KeyDashes oldDelegate) => oldDelegate.color != color || oldDelegate.dash != dash || oldDelegate.gap != gap;
}
