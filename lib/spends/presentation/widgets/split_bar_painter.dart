import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// The amounts a split bar shows, in paise (SPEC BR-20 page 2, BR-21).
typedef SplitAmounts = ({int bills, int saved, int everyday, int income});

/// The colours a split bar is painted with, from the theme's tokens.
typedef SplitColours = ({Color ink, Color ink2, Color soft, Color sunk, Color gap});

/// Paints the split bar against what came in, for Spends' split card and the month story's page 2
/// alike (SPEC FR-SP-4b, BR-20): *Bills* (solid `ink`), *Saved* (an `ink` outline at least
/// [minSaved] wide), *Everyday* (the [SplitColours.soft] fill), then the empty `sunk` track with an
/// `ink2` edge. Past income the bar is hatched after a tick (UI_DESIGN §5.4, accessibility review 46).
class SplitBarPainter extends CustomPainter {
  const SplitBarPainter({required this.amounts, required this.colours});

  final SplitAmounts amounts;
  final SplitColours colours;

  static const double radius = 10;
  static const double minSaved = 12;
  static const double _gap = 2;
  static const double _outline = 2;
  static const double _edge = 1;
  static const double _hatchStep = 6;

  @override
  void paint(Canvas canvas, Size size) {
    final RRect track = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(radius));
    canvas
      ..save()
      ..clipRRect(track)
      ..drawRect(Offset.zero & size, Paint()..color = colours.sunk);
    final List<double> widths = _widths(size.width);
    final double billsEnd = widths[0];
    final double savedEnd = billsEnd + widths[1];
    _fill(canvas, Rect.fromLTRB(0, 0, billsEnd, size.height), colours.ink);
    if (amounts.saved > 0) {
      _outlined(canvas, Rect.fromLTRB(billsEnd, 0, savedEnd, size.height));
    }
    _fill(canvas, Rect.fromLTRB(savedEnd, 0, savedEnd + widths[2], size.height), colours.soft);
    _over(canvas, size);
    canvas
      ..restore()
      ..drawRRect(track.deflate(_edge / 2), Paint()..style = PaintingStyle.stroke..strokeWidth = _edge..color = colours.ink2);
  }

  /// Bills, saved and everyday widths; saved never thinner than [minSaved] when above ₹0.
  List<double> _widths(double width) {
    final int scale = math.max(amounts.bills + amounts.saved + amounts.everyday, amounts.income);
    if (scale == 0) {
      return const <double>[0, 0, 0];
    }
    final double saved = amounts.saved > 0 ? math.max(minSaved, width * amounts.saved / scale) : 0;
    final double rest = width - saved;
    final int others = math.max(scale - amounts.saved, 1);
    return <double>[rest * amounts.bills / others, saved, rest * amounts.everyday / others];
  }

  void _fill(Canvas canvas, Rect rect, Color color) {
    if (rect.width > _gap) {
      canvas.drawRect(Rect.fromLTRB(rect.left, rect.top, rect.right - _gap, rect.bottom), Paint()..color = color);
    }
  }

  void _outlined(Canvas canvas, Rect rect) {
    final Rect inner = Rect.fromLTRB(rect.left, rect.top, rect.right - _gap, rect.bottom).deflate(_outline / 2);
    canvas
      ..drawRect(inner, Paint()..color = colours.gap)
      ..drawRect(inner, Paint()..style = PaintingStyle.stroke..strokeWidth = _outline..color = colours.ink);
  }

  void _over(Canvas canvas, Size size) {
    final int used = amounts.bills + amounts.saved + amounts.everyday;
    if (amounts.income <= 0 || used <= amounts.income) {
      return;
    }
    final double from = size.width * amounts.income / used;
    final Rect past = Rect.fromLTRB(from, 0, size.width, size.height);
    canvas
      ..save()
      ..clipRect(past)
      ..drawRect(past, Paint()..color = colours.gap);
    final Paint stripe = Paint()..color = colours.ink..strokeWidth = _hatchStep / 2;
    for (double x = from - size.height; x < size.width; x += _hatchStep) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), stripe);
    }
    canvas
      ..restore()
      ..drawRect(Rect.fromLTWH(from - _gap / 2, 0, _gap, size.height), Paint()..color = colours.ink);
  }

  @override
  bool shouldRepaint(SplitBarPainter oldDelegate) => oldDelegate.amounts != amounts || oldDelegate.colours != colours;
}
