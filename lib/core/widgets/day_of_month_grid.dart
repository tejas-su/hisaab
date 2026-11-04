import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';

import '../design/hisaab_dimensions.dart';
import '../design/hisaab_shapes.dart';
import '../extensions/build_context_extensions.dart';
import 'pressable.dart';

/// Days 1–31 in a calendar-like grid of seven; tapping a day picks it.
///
/// The [selected] day, the bill's current one, lifts one layer to `control` with an `ink`
/// dot and is announced as selected (D118).
class DayOfMonthGrid extends StatelessWidget {
  const DayOfMonthGrid({super.key, required this.onDay, this.selected = const Option<int>.none()});

  final ValueChanged<int> onDay;
  final Option<int> selected;

  static const double _dotSize = 6;
  static const double _dotInset = 6;

  static const int _columns = 7;
  static const int _days = 31;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int row = 0; row * _columns < _days; row++)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 6),
              child: Row(
                children: <Widget>[
                  for (int column = 0; column < _columns; column++) ...<Widget>[
                    if (column > 0) const SizedBox(width: 6),
                    Expanded(child: _day(context, row * _columns + column + 1)),
                  ],
                ],
              ),
            ),
        ],
      );

  Widget _day(BuildContext context, int day) {
    if (day > _days) {
      return const SizedBox.shrink();
    }
    final String label = '$day';
    final bool picked = selected == Option<int>.of(day);
    final TextStyle? text = Theme.of(context).textTheme.titleMedium;
    return Pressable(
      key: ValueKey<String>('day-$day'),
      semanticLabel: label,
      selected: picked,
      onPressed: () => onDay(day),
      builder: (BuildContext context, bool pressed) => Stack(
        children: <Widget>[
          Container(
            constraints: const BoxConstraints(minHeight: HisaabSizes.minTouchTarget),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: _fill(context, pressed: pressed, picked: picked),
              shape: HisaabShapes.squircle(HisaabRadii.chip),
            ),
            child: Text(label, style: picked ? text?.copyWith(fontWeight: FontWeight.w600) : text),
          ),
          if (picked)
            PositionedDirectional(
              top: _dotInset,
              end: _dotInset,
              child: Container(
                key: const ValueKey<String>('day-picked-dot'),
                width: _dotSize,
                height: _dotSize,
                decoration: BoxDecoration(color: context.colors.ink, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }

  // why: a pick lifts one layer, like a chosen chip on the page (D118); pressing still steps to hairline.
  static Color _fill(BuildContext context, {required bool pressed, required bool picked}) {
    if (pressed) {
      return context.colors.hairline;
    }
    return picked ? context.colors.control : context.colors.sunk;
  }
}
