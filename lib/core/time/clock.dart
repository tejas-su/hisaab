import 'calendar_date.dart';

/// The app's source of "now"; inject it so date logic can be tested on any day.
abstract class Clock {
  const Clock();

  /// The current instant.
  DateTime now();

  /// Today's calendar date in the device's time zone.
  CalendarDate today() => CalendarDate.fromDateTime(now());

  /// The time left until the next local midnight, when "today" changes (SPEC BR-8).
  Duration untilTomorrow() {
    final DateTime current = now();
    return DateTime(current.year, current.month, current.day + 1).difference(current);
  }
}

/// The real device clock.
final class SystemClock extends Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}
