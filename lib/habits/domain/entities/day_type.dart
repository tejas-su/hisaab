import '../../../core/time/calendar_date.dart';

/// The two kinds of day a habit is learned on apart (SPEC BR-17).
enum DayType {
  /// Monday to Friday.
  weekday,

  /// Saturday and Sunday.
  weekend;

  /// The day type of [date].
  static DayType of(CalendarDate date) => date.weekday >= DateTime.saturday ? weekend : weekday;
}
