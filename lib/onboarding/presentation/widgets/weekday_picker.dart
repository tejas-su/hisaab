import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/widgets/hisaab_chip.dart';

/// Monday to Sunday as big chips; tapping one picks it ([DateTime.monday] … [DateTime.sunday]).
class WeekdayPicker extends StatelessWidget {
  const WeekdayPicker({super.key, required this.onWeekday});

  final ValueChanged<int> onWeekday;

  // why: 1 Jan 2024 was a Monday, so day i of that week has weekday i.
  static DateTime _sample(int weekday) => DateTime(2024, 1, weekday);

  @override
  Widget build(BuildContext context) {
    final DateFormat names = DateFormat.EEEE(Localizations.localeOf(context).toString());
    return Wrap(
      spacing: HisaabSpacing.s,
      runSpacing: HisaabSpacing.s,
      children: <Widget>[
        for (int weekday = DateTime.monday; weekday <= DateTime.sunday; weekday++)
          HisaabChip(
            key: ValueKey<String>('weekday-$weekday'),
            label: names.format(_sample(weekday)),
            onPressed: () => onWeekday(weekday),
          ),
      ],
    );
  }
}
