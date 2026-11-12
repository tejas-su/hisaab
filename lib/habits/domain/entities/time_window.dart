import 'package:equatable/equatable.dart';

import '../habit_rules.dart';

/// The stretch of the day in which a habit is usually logged (SPEC BR-17); it may cross midnight.
final class TimeWindow extends Equatable {
  /// Creates a window of [lengthMinutes] (1–1440) starting at [startMinute] of the day (0–1439).
  const TimeWindow({required this.startMinute, required this.lengthMinutes});

  static const int _minutesPerHour = 60;
  static const int _hoursPerDay = 24;

  /// The first minute inside the window, counted from midnight.
  final int startMinute;

  /// How long the window is; its end minute is outside it.
  final int lengthMinutes;

  /// Whether [minuteOfDay] (0–1439) is inside the window.
  bool contains(int minuteOfDay) => (minuteOfDay - startMinute) % HabitRules.minutesPerDay < lengthMinutes;

  /// The minute of the day half-way through the window.
  int get middleMinute => (startMinute + lengthMinutes ~/ 2) % HabitRules.minutesPerDay;

  /// The hour (0–23) nearest [middleMinute], for "around 10 am"; a half hour rounds up.
  int get aroundHour => (middleMinute + _minutesPerHour ~/ 2) ~/ _minutesPerHour % _hoursPerDay;

  @override
  List<Object?> get props => <Object?>[startMinute, lengthMinutes];
}
