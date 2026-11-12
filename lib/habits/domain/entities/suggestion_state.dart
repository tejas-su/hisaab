import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/time/calendar_date.dart';

/// What the user has told one category's *your usual* to do: stay quiet, rest, or forget
/// (SPEC BR-17). It holds a category id and dates only.
final class SuggestionState extends Equatable {
  /// Creates the state of category [categoryId]; nothing is set unless given.
  const SuggestionState({
    required this.categoryId,
    this.quietOn = const Option<CalendarDate>.none(),
    this.restUntil = const Option<CalendarDate>.none(),
    this.forgottenAt = const Option<DateTime>.none(),
  });

  /// The category this state belongs to.
  final int categoryId;

  /// The day of the last Undo after a pill add; the category is quiet for the rest of that day.
  /// [None] when the pill add was never undone.
  final Option<CalendarDate> quietOn;

  /// The last day of a rest; the category suggests again the day after. [None] when it never rested.
  final Option<CalendarDate> restUntil;

  /// When the user tapped *Forget*, in local time; the category's entries logged before it no
  /// longer feed its habit. [None] when it was never forgotten.
  final Option<DateTime> forgottenAt;

  @override
  List<Object?> get props => <Object?>[categoryId, quietOn, restUntil, forgottenAt];
}
