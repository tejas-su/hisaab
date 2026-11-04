import 'dart:math' as math;

import 'package:intl/intl.dart';

import '../../core/time/calendar_date.dart';
import '../../core/widgets/week_bars/week_bars_data.dart';
import '../../ledger/ledger.dart';

/// Maps a [CycleSummary]'s week to the *This week* bars, Monday to Sunday (SPEC BR-6a).
abstract final class WeekBarsMapper {
  static const int _daysInWeek = 7;

  /// Every height is a share of the week's tallest spend or share, so the tallest reaches the top.
  static WeekBarsData of(CycleSummary summary) {
    final CalendarDate monday = _mondayOf(summary.today);
    final int tallest = summary.week.fold(0, (int top, WeekDay day) => math.max(top, math.max(day.spent.amountMinor, day.share.amountMinor)));
    final double scale = tallest == 0 ? 1 : tallest.toDouble();
    return WeekBarsData(
      bars: <WeekBar>[for (int i = 0; i < _daysInWeek; i++) _bar(summary, monday.addDays(i), scale)],
      todayIndex: summary.today.weekday - DateTime.monday,
    );
  }

  /// The locale's narrow weekday names, Monday first ("M T W T F S S" in English).
  static List<String> letters(String locale) {
    final DateFormat narrow = DateFormat('EEEEE', locale);
    final DateTime aMonday = DateTime(2026, 10, 26);
    return <String>[for (int i = 0; i < _daysInWeek; i++) narrow.format(aMonday.add(Duration(days: i)))];
  }

  static WeekBar _bar(CycleSummary summary, CalendarDate date, double scale) {
    final WeekDay? day = summary.week.where((WeekDay d) => d.date == date).firstOrNull;
    if (day != null) {
      return WeekBar(
        kind: date == summary.today ? WeekBarKind.today : WeekBarKind.past,
        spent: day.spent.amountMinor / scale,
        share: day.share.amountMinor / scale,
      );
    }
    final bool toCome = date.isAfter(summary.today) && summary.cycle.contains(date);
    return WeekBar(kind: toCome ? WeekBarKind.future : WeekBarKind.none);
  }

  static CalendarDate _mondayOf(CalendarDate day) => day.addDays(DateTime.monday - day.weekday);
}
