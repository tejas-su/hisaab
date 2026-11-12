import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../../domain/entities/day_type.dart';
import '../../domain/entities/forgotten_usual.dart';
import '../../domain/entities/habit_index.dart';
import '../../domain/entities/usual_habit.dart';
import '../../domain/usecase/forget_usual.dart';
import '../../domain/usecase/get_habit_index.dart';
import '../../domain/usecase/restore_usual.dart';
import 'usual_row_event.dart';
import 'usual_row_state.dart';

/// Owns the *Your usual* row of one category's sheet in Settings (SPEC FR-SE-2 AC-6): the habit
/// to show, *Forget*, and its Undo.
///
/// Lives as long as the sheet's summary. The route adds [UsualRowLoadRequested] when it builds
/// it, and the row adds [UsualRowForgetRequested] and [UsualRowForgetUndone].
class UsualRowBloc extends Bloc<UsualRowEvent, UsualRowState> {
  /// Shows the habit of category [categoryId], read through [_getIndex]; [_forget] and
  /// [_restore] write the category's state, and [_clock] says which day type is today's.
  UsualRowBloc({
    required this._categoryId,
    required this._getIndex,
    required this._forget,
    required this._restore,
    required this._clock,
  }) : super(const UsualRowEmpty()) {
    // why: the newest read wins, so an older, slower one can't bring back a row that is gone.
    on<UsualRowLoadRequested>(
      (UsualRowLoadRequested event, Emitter<UsualRowState> emit) => _load(emit),
      transformer: restartable(),
    );
    // why: a second tap while the first is being written must not store a second Forget, whose
    // "previous state" would be the first one and so could never be undone.
    on<UsualRowForgetRequested>(_onForgetRequested, transformer: droppable());
    // why: a second Undo while the first is being written must not restore twice.
    on<UsualRowForgetUndone>(_onForgetUndone, transformer: droppable());
  }

  final int _categoryId;
  final GetHabitIndex _getIndex;
  final ForgetUsual _forget;
  final RestoreUsual _restore;
  final Clock _clock;

  /// Shows the category's habit, preferring today's day type; a failed read shows no row.
  Future<void> _load(Emitter<UsualRowState> emit) async {
    final Either<Failure, HabitIndex> loaded = await _getIndex(const NoParams()).run();
    final Option<UsualHabit> habit = loaded
        .mapLeft(_logFailure('usual_row.load_failed'))
        .toOption()
        .flatMap((HabitIndex index) => index.habitFor(_categoryId, preferring: DayType.of(_clock.today())));
    emit(habit.match(UsualRowEmpty.new, UsualRowShown.new));
  }

  /// Forgets the habit shown; a failed write keeps the row.
  Future<void> _onForgetRequested(UsualRowForgetRequested event, Emitter<UsualRowState> emit) async {
    if (state is! UsualRowShown) {
      return;
    }
    final Either<Failure, ForgottenUsual> forgotten = await _forget(_categoryId).run();
    forgotten.match(
      _logFailure('usual_row.forget_failed'),
      (ForgottenUsual done) => emit(UsualRowForgotten(done)),
    );
  }

  /// Puts back what *Forget* replaced, then reloads so the row returns.
  Future<void> _onForgetUndone(UsualRowForgetUndone event, Emitter<UsualRowState> emit) async {
    final UsualRowState current = state;
    if (current is! UsualRowForgotten) {
      return;
    }
    final Either<Failure, Unit> restored = await _restore(current.forgotten).run();
    restored.mapLeft(_logFailure('usual_row.restore_failed'));
    await _load(emit);
  }

  // why: the type only. A failure's message can carry a row's text, and nothing about a habit
  // may reach the log (NFR-3, BR-17).
  static void Function(Failure) _logFailure(String tag) =>
      (Failure failure) => AppLogger.log(tag: tag, data: <String, Object?>{'type': failure.runtimeType.toString()});
}
