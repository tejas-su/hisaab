import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/notifications/nudge_notice.dart';
import '../../../core/notifications/nudges.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import '../entities/habit_index.dart';
import '../entities/nudge.dart';
import '../entities/nudge_state.dart';
import '../habit_index_builder.dart';
import '../nudge_planner.dart';
import '../nudge_rules.dart';
import '../nudge_settler.dart';
import '../repository/nudge_state_repository.dart';
import 'get_habit_index.dart';

/// Arms the daily nudges, or removes them all when the user switched them off (SPEC BR-22.3,
/// BR-22.4, BR-22.5, BR-22.8). Run on start, on resume and after every write; idempotent.
///
/// The param is whether the user wants nudges.
final class ArmNudges implements UseCase<Unit, bool> {
  /// Reads habits through [getHabitIndex], what each nudge remembers from [nudgeStates], entries
  /// from [ledger] and categories from [categories]; arms through [nudges]. [categoryLabel] is the
  /// name a nudge shows for a category, and "today" is [clock]'s.
  const ArmNudges({
    required this._getHabitIndex,
    required this._nudgeStates,
    required this._ledger,
    required this._categories,
    required this._nudges,
    required this._clock,
    required this._categoryLabel,
  });

  final GetHabitIndex _getHabitIndex;
  final NudgeStateRepository _nudgeStates;
  final LedgerRepository _ledger;
  final CategoryRepository _categories;
  final Nudges _nudges;
  final Clock _clock;
  final String Function(Category) _categoryLabel;

  /// Returns [Right] with [unit] once the nudges are armed, or [Left] with `DatabaseFailure` or
  /// `InvalidDataFailure` when anything can't be read or stored, in which case nothing is armed
  /// for a read failure.
  @override
  TaskEither<Failure, Unit> call(bool params) {
    if (!params) {
      return _arm(const <NudgeNotice>[]).flatMap((Unit _) => _disarmStates());
    }
    return _nudgeStates.all().flatMap(
          (Map<int, NudgeState> stored) => _categories.all().flatMap(
                (List<Category> categories) =>
                    _settle(stored, categories).flatMap((Map<int, NudgeState> settled) => _plan(settled, categories)),
              ),
        );
  }

  TaskEither<Failure, Unit> _arm(List<NudgeNotice> notices) => TaskEither<Failure, Unit>(() async {
        await _nudges.arm(notices);
        return Either<Failure, Unit>.right(unit);
      });

  // why: a nudge cancelled by switching off was never shown, so a later switch-on must not
  // settle it as ignored (BR-22.4); the streak and rest stay.
  TaskEither<Failure, Unit> _disarmStates() => _nudgeStates.all().flatMap(
        (Map<int, NudgeState> stored) => stored.values
            .where((NudgeState state) => state.armedFor.isSome())
            .fold(
              TaskEither<Failure, Unit>.right(unit),
              (TaskEither<Failure, Unit> acc, NudgeState state) => acc.flatMap(
                (Unit _) => _nudgeStates.put(_withArmedFor(state, state.categoryId, const Option<DateTime>.none())),
              ),
            ),
      );

  TaskEither<Failure, Unit> _plan(Map<int, NudgeState> settled, List<Category> categories) =>
      _getHabitIndex(const NoParams()).flatMap(
        (HabitIndex index) {
          final List<Nudge> planned = NudgePlanner.plan(
            index,
            now: _clock.now(),
            categories: categories,
            nudgeStates: settled,
            hasEnoughDays: index.warmedUp,
          );
          return _arm(planned.map((Nudge nudge) => _noticeOf(nudge, categories)).toList())
              .flatMap((Unit _) => _record(planned, settled));
        },
      );

  NudgeNotice _noticeOf(Nudge nudge, List<Category> categories) => NudgeNotice(
        id: nudge.id,
        at: nudge.at,
        categoryName: nudge.categoryId.flatMap(
          (int id) => Option<Category>.fromNullable(categories.where((Category c) => c.id == id).firstOrNull)
              .map(_categoryLabel),
        ),
      );

  TaskEither<Failure, Map<int, NudgeState>> _settle(Map<int, NudgeState> stored, List<Category> categories) =>
      stored.values.fold(
        TaskEither<Failure, Map<int, NudgeState>>.right(stored),
        (TaskEither<Failure, Map<int, NudgeState>> acc, NudgeState state) => acc.flatMap(
          (Map<int, NudgeState> settled) => _settleOne(state, categories).map(
            (NudgeState result) => <int, NudgeState>{...settled, state.categoryId: result},
          ),
        ),
      );

  TaskEither<Failure, NudgeState> _settleOne(NudgeState state, List<Category> categories) {
    final DateTime now = _clock.now();
    return state.armedFor.match(
      () => TaskEither<Failure, NudgeState>.right(state),
      (DateTime armed) {
        if (!armed.isBefore(now)) {
          return TaskEither<Failure, NudgeState>.right(state);
        }
        final CalendarDate day = CalendarDate.fromDateTime(armed);
        return _ledger.entriesBetween(day, day).flatMap((List<Entry> entries) {
          final NudgeState result = NudgeSettler.settle(
            state,
            now: now,
            loggedAt: _loggedAt(entries, state.categoryId, categories),
          );
          return result == state
              ? TaskEither<Failure, NudgeState>.right(state)
              : _nudgeStates.put(result).map((Unit _) => result);
        });
      },
    );
  }

  // why: only what the user typed into a shown Spent category counts as logging; posted bills,
  // *not logged* fixes and hidden categories are not a reaction to a nudge.
  static List<DateTime> _loggedAt(List<Entry> entries, int categoryId, List<Category> categories) {
    final Set<int> shown = <int>{
      for (final Category category in categories.where((Category c) => !c.hidden && c.kind == EntryKind.spent))
        category.id,
    };
    return entries
        .where(HabitIndexBuilder.isTypedSpend)
        .where((Entry entry) => shown.contains(entry.categoryId))
        .where((Entry entry) => categoryId == NudgeRules.generalCategoryId || entry.categoryId == categoryId)
        .map((Entry entry) => entry.createdAt)
        .toList();
  }

  // why: a state holds one armedFor, so the earliest nudge of each category is recorded and a
  // later date is recorded by a later run. A nudge already past its time keeps its armedFor
  // until it is settled, so tomorrow's arming never hides today's verdict.
  TaskEither<Failure, Unit> _record(List<Nudge> planned, Map<int, NudgeState> settled) {
    final DateTime now = _clock.now();
    final Map<int, DateTime> earliest = <int, DateTime>{};
    for (final Nudge nudge in planned) {
      earliest.putIfAbsent(nudge.categoryId.getOrElse(() => NudgeRules.generalCategoryId), () => nudge.at);
    }
    final List<NudgeState> changes = <NudgeState>[
      for (final MapEntry<int, DateTime> next in earliest.entries)
        if (!_awaitsVerdict(settled[next.key], now))
          _withArmedFor(settled[next.key], next.key, Option<DateTime>.of(next.value)),
      for (final NudgeState state in settled.values)
        if (!earliest.containsKey(state.categoryId) && state.armedFor.isSome() && !_awaitsVerdict(state, now))
          _withArmedFor(state, state.categoryId, const Option<DateTime>.none()),
    ].where((NudgeState state) => state != settled[state.categoryId]).toList();
    return changes.fold(
      TaskEither<Failure, Unit>.right(unit),
      (TaskEither<Failure, Unit> acc, NudgeState state) => acc.flatMap((Unit _) => _nudgeStates.put(state)),
    );
  }

  static bool _awaitsVerdict(NudgeState? state, DateTime now) =>
      state != null && state.armedFor.match(() => false, (DateTime armed) => !armed.isAfter(now));

  static NudgeState _withArmedFor(NudgeState? state, int categoryId, Option<DateTime> armedFor) => NudgeState(
        categoryId: categoryId,
        armedFor: armedFor,
        ignoredStreak: state?.ignoredStreak ?? 0,
        restUntil: state?.restUntil ?? const Option<CalendarDate>.none(),
      );
}
