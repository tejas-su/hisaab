import 'package:fpdart/fpdart.dart';

import '../../core/time/calendar_date.dart';
import 'entities/nudge_state.dart';
import 'nudge_rules.dart';

/// Turns an armed nudge into a verdict, *worked* or *ignored*, once its window has passed
/// (SPEC BR-22.5).
abstract final class NudgeSettler {
  /// Settles [state] as of [now], given [loggedAt], the `created_at` of the Spent entries dated
  /// the armed day (any category for the general nudge).
  ///
  /// Returns [state] unchanged when it is not armed or the window is still open. Otherwise
  /// `armedFor` is cleared, so settling again changes nothing, and the streak and rest follow
  /// the verdict.
  static NudgeState settle(
    NudgeState state, {
    required DateTime now,
    required List<DateTime> loggedAt,
  }) => state.armedFor.match(
    () => state,
    (DateTime armed) => _windowEnd(armed).isBefore(now) ? _verdict(state, armed, loggedAt) : state,
  );

  // why: the window is inclusive at both ends, so the verdict waits until strictly after it.
  static DateTime _windowEnd(DateTime armed) =>
      armed.add(const Duration(minutes: NudgeRules.workedWindowMinutes));

  static NudgeState _verdict(NudgeState state, DateTime armed, List<DateTime> loggedAt) {
    final NudgeState cleared = _cleared(state);
    // why: a log before the nudge time cancels the nudge; ignoring and dismissing are the same
    // signal only for a nudge that was shown, so a cancelled one counts as neither verdict.
    if (loggedAt.any((DateTime at) => at.isBefore(armed))) {
      return cleared;
    }
    final DateTime end = _windowEnd(armed);
    final bool worked = loggedAt.any((DateTime at) => !at.isAfter(end));
    return worked ? _worked(cleared) : _ignored(cleared, armed);
  }

  static NudgeState _cleared(NudgeState state) => NudgeState(
    categoryId: state.categoryId,
    ignoredStreak: state.ignoredStreak,
    restUntil: state.restUntil,
  );

  static NudgeState _worked(NudgeState cleared) =>
      NudgeState(categoryId: cleared.categoryId, restUntil: cleared.restUntil);

  static NudgeState _ignored(NudgeState cleared, DateTime armed) {
    final int streak = cleared.ignoredStreak + 1;
    if (streak < NudgeRules.ignoredLimit) {
      return NudgeState(categoryId: cleared.categoryId, ignoredStreak: streak, restUntil: cleared.restUntil);
    }
    return NudgeState(
      categoryId: cleared.categoryId,
      restUntil: Option<CalendarDate>.of(CalendarDate.fromDateTime(armed).addDays(NudgeRules.restDays)),
    );
  }
}
