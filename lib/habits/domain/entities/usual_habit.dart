import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import 'day_type.dart';
import 'time_window.dart';

/// A Regular habit (SPEC BR-17): one category the user logs with one amount, around one time, on
/// one kind of day.
final class UsualHabit extends Equatable {
  /// Creates a habit; only a profile that passes all four of BR-17's rules becomes one.
  const UsualHabit({
    required this.categoryId,
    required this.dayType,
    required this.pooled,
    required this.window,
    required this.amount,
    required this.hitDays,
    required this.activeDays,
    required this.lastHit,
    required this.fading,
  });

  /// The category the habit is in.
  final int categoryId;

  /// The kind of day the habit is offered on.
  final DayType dayType;

  /// Whether it was learned from all days because [dayType]'s own entries were too few (E64).
  final bool pooled;

  /// When in the day it is usually logged.
  final TimeWindow window;

  /// The amount it is usually logged with, exactly as the user typed it.
  final Money amount;

  /// Of [activeDays], the days with an entry inside [window].
  final int hitDays;

  /// The days in the 28 before today on which anything was logged; for a habit that is not
  /// [pooled], only days of [dayType].
  final int activeDays;

  /// When the newest entry inside [window] was logged.
  final DateTime lastHit;

  /// Whether the window was missed on the 3 most recent days of [dayType] with any entry; a
  /// fading habit is still Regular but is not suggested until it is hit again.
  final bool fading;

  @override
  List<Object?> get props =>
      <Object?>[categoryId, dayType, pooled, window, amount, hitDays, activeDays, lastHit, fading];
}
