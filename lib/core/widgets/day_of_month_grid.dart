import 'package:flutter/material.dart';

import '../design/hisaab_dimensions.dart';
import '../design/hisaab_shapes.dart';
import '../extensions/build_context_extensions.dart';
import 'pressable.dart';

/// Days 1–31 in a calendar-like grid of seven; tapping a day picks it.
class DayOfMonthGrid extends StatelessWidget {
  const DayOfMonthGrid({super.key, required this.onDay});

  final ValueChanged<int> onDay;

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
    return Pressable(
      key: ValueKey<String>('day-$day'),
      semanticLabel: label,
      onPressed: () => onDay(day),
      builder: (BuildContext context, bool pressed) => Container(
        constraints: const BoxConstraints(minHeight: HisaabSizes.minTouchTarget),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: pressed ? context.colors.hairline : context.colors.sunk,
          shape: HisaabShapes.squircle(HisaabRadii.chip),
        ),
        child: Text(label, style: Theme.of(context).textTheme.titleMedium),
      ),
    );
  }
}
