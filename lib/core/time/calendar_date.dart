import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../errors/failure.dart';

/// A day on the calendar with no time of day, so cycle maths can't drift across midnight or DST.
final class CalendarDate extends Equatable implements Comparable<CalendarDate> {
  /// Creates a date without validation; use [CalendarDate.validate] for untrusted input.
  const CalendarDate(this.year, this.month, this.day);

  /// The calendar day of [dateTime] in its own time zone, ignoring the time.
  factory CalendarDate.fromDateTime(DateTime dateTime) =>
      CalendarDate(dateTime.year, dateTime.month, dateTime.day);

  /// Validates a date.
  ///
  /// Returns [Right] with the date, or [Left] with [InvalidDataFailure] when it doesn't
  /// exist (e.g. 30 Feb, month 13).
  static Either<Failure, CalendarDate> validate(int year, int month, int day) {
    final bool validMonth = month >= 1 && month <= 12;
    if (!validMonth || day < 1 || day > daysInMonth(year, month)) {
      return Either<Failure, CalendarDate>.left(InvalidDataFailure('Invalid date $year-$month-$day'));
    }
    return Either<Failure, CalendarDate>.right(CalendarDate(year, month, day));
  }

  /// Parses `YYYY-MM-DD`, the storage format.
  ///
  /// Returns [Right] with the date, or [Left] with [InvalidDataFailure] for malformed or
  /// impossible dates.
  static Either<Failure, CalendarDate> parse(String text) =>
      Option<RegExpMatch>.fromNullable(_isoPattern.firstMatch(text))
          .toEither<Failure>(() => InvalidDataFailure('Not an ISO date: "$text"'))
          .flatMap(
            (RegExpMatch match) => validate(
              int.parse(match.group(1) ?? ''),
              int.parse(match.group(2) ?? ''),
              int.parse(match.group(3) ?? ''),
            ),
          );

  static final RegExp _isoPattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  final int year;

  /// Month of the year, 1–12.
  final int month;

  /// Day of the month, 1–31.
  final int day;

  /// Number of days in [month] of [year], accounting for leap years.
  static int daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;

  /// ISO weekday: [DateTime.monday] (1) to [DateTime.sunday] (7).
  int get weekday => _utc.weekday;

  /// Returns the date [days] later (negative for earlier).
  CalendarDate addDays(int days) => CalendarDate.fromDateTime(DateTime.utc(year, month, day + days));

  /// Whole days from this date to [other]; negative when [other] is earlier.
  int daysUntil(CalendarDate other) => other._utc.difference(_utc).inDays;

  bool isBefore(CalendarDate other) => compareTo(other) < 0;

  bool isAfter(CalendarDate other) => compareTo(other) > 0;

  /// Formats as `YYYY-MM-DD` for storage.
  String toIso() =>
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  // why: UTC has no DST jumps, so day differences are always whole days.
  DateTime get _utc => DateTime.utc(year, month, day);

  @override
  int compareTo(CalendarDate other) => _utc.compareTo(other._utc);

  @override
  List<Object?> get props => <Object?>[year, month, day];

  @override
  String toString() => toIso();
}
