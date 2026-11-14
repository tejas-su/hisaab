import 'package:material_ui/material_ui.dart';

import '../../../core/extensions/build_context_extensions.dart';
import 'day_bars_painter.dart';

/// A cycle's days as bars (SPEC FR-SP-7 AC-4, D194), [height] tall, hidden from screen readers:
/// the sentences beside it carry what it shows. Under it, when [dates] is set, the first, the
/// biggest and the last day are named; a middle date that would touch an end is dropped.
class DayBars extends StatelessWidget {
  const DayBars({super.key, required this.data, required this.height, this.dates, this.peakIndex = 0});

  final DayBarsData data;
  final double height;

  /// The first, the biggest and the last day's labels, or null for the small preview.
  final (String, String, String)? dates;
  final int peakIndex;

  /// A middle label narrower than this from an end label is dropped.
  static const double _labelRoom = 56;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            RepaintBoundary(
              child: SizedBox(
                height: height,
                child: CustomPaint(
                  painter: DayBarsPainter(data: data, ink: context.colors.ink, ink2: context.colors.ink2, axis: context.colors.hairline),
                ),
              ),
            ),
            if (dates case (final String first, final String peak, final String last)) _dateRow(context, first, peak, last),
          ],
        ),
      );

  Widget _dateRow(BuildContext context, String first, String peak, String last) {
    final TextStyle? style = Theme.of(context).textTheme.labelSmall;
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints box) {
        final double slot = box.maxWidth / data.perDay.length;
        final double peakX = slot * peakIndex + slot / 2;
        final bool roomForPeak = peakX > _labelRoom && peakX < box.maxWidth - _labelRoom;
        return Stack(
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[Text(first, style: style), Text(last, style: style)],
            ),
            if (roomForPeak)
              PositionedDirectional(
                start: peakX - _labelRoom / 2,
                width: _labelRoom,
                child: Text(peak, style: style?.copyWith(color: context.colors.ink), textAlign: TextAlign.center),
              ),
          ],
        );
      },
    );
  }
}
