/// Every threshold of *your usual* (SPEC BR-17), named once.
abstract final class HabitRules {
  /// Days of entries a habit is learned from, today included (today − 55 … today).
  static const int horizonDays = 56;

  /// Days before today over which the share of hit days is counted (rule 3).
  static const int shareDays = 28;

  /// Days after which an entry weighs half as much.
  static const int halfLifeDays = 14;

  /// Half-hour slots in a day.
  static const int slotsPerDay = 48;

  /// Minutes in one slot.
  static const int slotMinutes = 30;

  /// Minutes a window is widened by on each side.
  static const int widenMinutes = 15;

  /// Minutes in a day, the longest a window can be.
  static const int minutesPerDay = 1440;

  /// Days since the first learned entry before anything is suggested (rule 1).
  static const int warmUpDays = 14;

  /// Days with a learned entry before anything is suggested (rule 1).
  static const int minActiveDays = 10;

  /// Entries inside the window a habit needs (rule 2).
  static const int minHits = 5;

  /// Rule 3's share of hit days, 3 in 5 (60%): [dayShareNum] over [dayShareDen].
  static const int dayShareNum = 3;

  /// See [dayShareNum].
  static const int dayShareDen = 5;

  /// Rule 4's weighted share of one amount, 7 in 10 (70%): [amountShareNum] over [amountShareDen].
  static const int amountShareNum = 7;

  /// See [amountShareNum].
  static const int amountShareDen = 10;

  /// Missed days in a row after which a habit stops suggesting.
  static const int missedRun = 3;

  /// Entries of its own a day type needs inside the pooled window to use the pooled habit.
  static const int pooledMinOwnHits = 2;

  /// Days within which a second Undo rests the category; day 14 counts.
  static const int undoWindowDays = 14;

  /// Days a rest lasts after the day it starts; the category is open again the day after.
  static const int restDays = 30;
}
