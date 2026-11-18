import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/time/calendar_date.dart';

/// What the daily nudge remembers about one category, or about the general nudge (SPEC BR-22.5,
/// BR-22.12). It holds ids, instants and dates only.
final class NudgeState extends Equatable {
  /// Creates the state of the nudge for [categoryId]; nothing is set unless given.
  const NudgeState({
    required this.categoryId,
    this.armedFor = const Option<DateTime>.none(),
    this.ignoredStreak = 0,
    this.restUntil = const Option<CalendarDate>.none(),
  });

  /// The category this state belongs to; 0 is the general nudge (BR-22.2).
  final int categoryId;

  /// When the nudge was last armed to show, in local time. [None] when it never was.
  final Option<DateTime> armedFor;

  /// Nudges settled *ignored* in a row (BR-22.5).
  final int ignoredStreak;

  /// The last day of the nudge's rest after three ignored in a row; it may show again the day
  /// after. [None] when it is not resting.
  final Option<CalendarDate> restUntil;

  @override
  List<Object?> get props => <Object?>[categoryId, armedFor, ignoredStreak, restUntil];
}
