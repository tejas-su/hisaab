import 'package:fpdart/fpdart.dart';

import '../../core/time/calendar_date.dart';
import 'entities/suggestion_state.dart';
import 'habit_rules.dart';

/// Whether a category's *your usual* may be suggested today (SPEC BR-17).
enum GateStatus {
  /// Nothing holds it back.
  open,

  /// A pill add was undone today; it is quiet until midnight.
  quietToday,

  /// It is resting for 30 days after a second Undo or a *Forget*.
  resting,
}

/// The quiet and rest rules of one category's *your usual* (SPEC BR-17). Pure: takes the day.
abstract final class SuggestionGate {
  /// The status of a category on [today]; [state] is [None] for a category with nothing stored.
  static GateStatus statusOf(Option<SuggestionState> state, {required CalendarDate today}) => state.match(
        () => GateStatus.open,
        (SuggestionState state) {
          // why: the rest runs to the end of its last day, so that day still rests (day 0 is the
          // day of the Undo or Forget, day 30 the last).
          if (state.restUntil.match(() => false, (CalendarDate last) => !today.isAfter(last))) {
            return GateStatus.resting;
          }
          final bool undoneToday = state.quietOn.match(() => false, (CalendarDate day) => day == today);
          return undoneToday ? GateStatus.quietToday : GateStatus.open;
        },
      );

  /// The state of category [categoryId] after a pill add is undone on [today].
  ///
  /// The category is quiet for the rest of [today]. When [state] holds an earlier Undo 0 to 14
  /// days before [today], it also rests until the end of the 30th day after [today].
  static SuggestionState afterUndo(
    Option<SuggestionState> state, {
    required int categoryId,
    required CalendarDate today,
  }) {
    final bool second = state.flatMap((SuggestionState state) => state.quietOn).match(
      () => false,
      (CalendarDate earlier) {
        final int daysSince = earlier.daysUntil(today);
        return daysSince >= 0 && daysSince <= HabitRules.undoWindowDays;
      },
    );
    return SuggestionState(
      categoryId: categoryId,
      quietOn: Option<CalendarDate>.of(today),
      restUntil: second
          ? Option<CalendarDate>.of(today.addDays(HabitRules.restDays))
          : state.flatMap((SuggestionState state) => state.restUntil),
      forgottenAt: state.flatMap((SuggestionState state) => state.forgottenAt),
      askedOn: state.flatMap((SuggestionState state) => state.askedOn),
    );
  }

  /// The state of category [categoryId] after *Forget* is tapped at [now], in local time.
  ///
  /// Entries logged before [now] stop feeding the category's habit, and it rests until the end
  /// of the 30th day after [now]'s date. The quiet day in [state] is kept.
  static SuggestionState afterForget(
    Option<SuggestionState> state, {
    required int categoryId,
    required DateTime now,
  }) =>
      SuggestionState(
        categoryId: categoryId,
        quietOn: state.flatMap((SuggestionState state) => state.quietOn),
        restUntil: Option<CalendarDate>.of(CalendarDate.fromDateTime(now).addDays(HabitRules.restDays)),
        forgottenAt: Option<DateTime>.of(now),
        askedOn: state.flatMap((SuggestionState state) => state.askedOn),
      );
}
