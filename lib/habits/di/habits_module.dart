import 'package:get_it/get_it.dart';

import '../../core/db/app_database.dart';
import '../../core/time/clock.dart';
import '../../ledger/ledger.dart';
import '../data/datasource/suggestion_state_local_data_source.dart';
import '../data/repository/suggestion_state_repository_impl.dart';
import '../domain/repository/suggestion_state_repository.dart';
import '../domain/usecase/forget_usual.dart';
import '../domain/usecase/get_habit_index.dart';
import '../domain/usecase/mark_missed_log_asked.dart';
import '../domain/usecase/restore_usual.dart';
import '../domain/usecase/undo_usual_add.dart';

/// Registers the habits repository and use cases; needs the core and ledger services
/// registered first.
void registerHabitsServices(GetIt getIt) {
  final Clock clock = getIt<Clock>();
  final SuggestionStateRepository states =
      SuggestionStateRepositoryImpl(source: SqfliteSuggestionStateLocalDataSource(getIt<AppDatabase>()));
  getIt
    ..registerSingleton<SuggestionStateRepository>(states)
    ..registerSingleton<GetHabitIndex>(
      GetHabitIndex(
        ledger: getIt<LedgerRepository>(),
        categories: getIt<CategoryRepository>(),
        states: states,
        clock: clock,
      ),
    )
    ..registerSingleton<UndoUsualAdd>(UndoUsualAdd(states: states, ledger: getIt<LedgerRepository>(), clock: clock))
    ..registerSingleton<ForgetUsual>(ForgetUsual(states: states, clock: clock))
    ..registerSingleton<MarkMissedLogAsked>(MarkMissedLogAsked(states: states, clock: clock))
    ..registerSingleton<RestoreUsual>(RestoreUsual(states: states));
}
