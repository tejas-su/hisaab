import 'package:equatable/equatable.dart';

import 'calendar_date.dart';

/// The run of days the user's money must last, from [start] to [end] inclusive.
final class PayCycle extends Equatable {
  /// Creates a cycle; [end] must not be before [start].
  const PayCycle({required this.start, required this.end});

  final CalendarDate start;

  /// The last day of the cycle, the day before the next payday.
  final CalendarDate end;

  /// Total days in the cycle.
  int get lengthInDays => start.daysUntil(end) + 1;

  /// Whether this is a weekly pay cycle; by BR-1 only weekly pay gives a 7-day cycle.
  bool get isWeek => lengthInDays == DateTime.daysPerWeek;

  /// Days left including [today] (SPEC BR-2); 1 on the last day.
  int daysLeftFrom(CalendarDate today) => today.daysUntil(end) + 1;

  /// Whole days of the cycle that passed before [today].
  int daysElapsedBefore(CalendarDate today) => start.daysUntil(today);

  /// Whether [date] falls inside the cycle.
  bool contains(CalendarDate date) => !date.isBefore(start) && !date.isAfter(end);

  @override
  List<Object?> get props => <Object?>[start, end];
}
