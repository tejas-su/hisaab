import '../../core/time/calendar_date.dart';
import 'detectors/missed_log_detector.dart';

/// Every threshold of the daily nudge (SPEC BR-22), named once.
abstract final class NudgeRules {
  /// Minutes after a window's end the nudge shows; the missed-log line's grace (BR-22.1).
  static const int graceMinutes = MissedLogDetector.graceMinutes;

  /// The latest minute of the day a nudge may show, 22:00 (BR-22.1); a nudge at exactly 22:00 shows.
  static const int latestMinute = 22 * 60;

  /// The minute of the day of the general nudge, 20:00 (BR-22.2).
  static const int generalMinute = 20 * 60;

  /// The category id the general nudge is stored and numbered under.
  static const int generalCategoryId = 0;

  /// Minutes after the nudge time in which a log counts as *worked*, both ends included (BR-22.5).
  static const int workedWindowMinutes = 60;

  /// Ignored nudges in a row that start a rest (BR-22.5).
  static const int ignoredLimit = 3;

  /// Days after the armed day the rest lasts; the armed day is day 0 (BR-22.5).
  static const int restDays = 30;

  /// The first day of the nudge ids' day count; the bill reminders use the same epoch.
  static const CalendarDate idEpoch = CalendarDate(2020, 1, 1);

  /// Where nudge ids start. A bill reminder id is `ruleId * 100000 + days`, below this for rule
  /// ids up to 19,999, so the two ranges never meet. The ids end below 2^31 for dates up to the
  /// year 2423.
  static const int idOffset = 2000000000;

  /// Ids reserved for each date; a category id is folded into this many.
  static const int idSlotsPerDate = 1000;
}
