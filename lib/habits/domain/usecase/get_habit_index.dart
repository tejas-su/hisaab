import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import '../entities/habit_index.dart';
import '../entities/habit_inputs.dart';
import '../entities/suggestion_state.dart';
import '../habit_index_builder.dart';
import '../habit_rules.dart';
import '../repository/suggestion_state_repository.dart';

/// Works out today's [HabitIndex] from the last 56 days of entries, the categories and the
/// stored quiet states (SPEC BR-17).
final class GetHabitIndex implements UseCase<HabitIndex, NoParams> {
  /// Reads entries from [_ledger], categories from [_categories], states from [_states] and
  /// "today" from [_clock].
  const GetHabitIndex({
    required this._ledger,
    required this._categories,
    required this._states,
    required this._clock,
  });

  final LedgerRepository _ledger;
  final CategoryRepository _categories;
  final SuggestionStateRepository _states;
  final Clock _clock;

  /// Returns [Right] with the index of today (empty for an empty ledger), or [Left] with
  /// `DatabaseFailure` or `InvalidDataFailure` when any of the three reads fails.
  @override
  TaskEither<Failure, HabitIndex> call(NoParams params) {
    final CalendarDate today = _clock.today();
    return _ledger.entriesBetween(today.addDays(-(HabitRules.horizonDays - 1)), today).flatMap(
          (List<Entry> entries) => _categories.all().flatMap(
                (List<Category> categories) => _states.all().map(
                      (Map<int, SuggestionState> states) => HabitIndexBuilder.build(
                        HabitInputs(entries: entries, categories: categories, states: states),
                        today: today,
                      ),
                    ),
              ),
        );
  }
}
