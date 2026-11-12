import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import '../../domain/entities/habit_index.dart';
import '../../domain/entities/usual_add.dart';
import '../../domain/usecase/get_habit_index.dart';
import '../../domain/usecase/undo_usual_add.dart';
import 'habits_event.dart';
import 'habits_state.dart';

/// Owns today's `HabitIndex` for the whole main screen, so the Add tray can read *your usual*
/// without waiting (SPEC FR-AD-10 AC-1), and the Undo of a one-tap add (BR-10).
///
/// Driven by [HabitsLoadRequested] (start, resume, midnight, back from Settings) and by every
/// write through [LedgerRepository.changes]. The app adds [HabitsUsualAdded] when the tray closes
/// after a pill tap, and the Undo notice adds [HabitsUsualUndoRequested].
class HabitsBloc extends Bloc<HabitsEvent, HabitsState> {
  /// Loads through [_getIndex], undoes through [_undoAdd] and reloads on each change of [ledger].
  HabitsBloc({
    required this._getIndex,
    required this._undoAdd,
    required LedgerRepository ledger,
  }) : super(const HabitsLoading()) {
    // why: every write reloads the habits; the newest read wins, so an older, slower one can't
    // land a stale index last.
    on<HabitsLoadRequested>(
      (HabitsLoadRequested event, Emitter<HabitsState> emit) => _load(emit),
      transformer: restartable(),
    );
    on<HabitsUsualAdded>(_onUsualAdded);
    // why: a second Undo while the first is being written must not delete twice, and would count
    // as the second Undo that rests the category for 30 days.
    on<HabitsUsualUndoRequested>(_onUsualUndoRequested, transformer: droppable());
    _changes = ledger.changes.listen((void _) => add(const HabitsLoadRequested()));
  }

  final GetHabitIndex _getIndex;
  final UndoUsualAdd _undoAdd;
  late final StreamSubscription<void> _changes;

  /// Works out today's index; a failed read keeps what is shown.
  Future<void> _load(Emitter<HabitsState> emit) async {
    final Either<Failure, HabitIndex> loaded = await _getIndex(const NoParams()).run();
    loaded.match(_logFailure('habits.load_failed'), (HabitIndex index) => emit(HabitsReady(index)));
  }

  // why: a pill is only ever shown from a ready state, so before the first load there is no add
  // to offer an Undo for.
  void _onUsualAdded(HabitsUsualAdded event, Emitter<HabitsState> emit) {
    final HabitsState current = state;
    if (current is! HabitsReady) {
      return;
    }
    emit(HabitsReady(current.index, added: Option<UsualAdd>.of(event.added)));
  }

  /// Deletes the added entry and quiets its category, then reloads so the offer is gone.
  Future<void> _onUsualUndoRequested(HabitsUsualUndoRequested event, Emitter<HabitsState> emit) async {
    final Either<Failure, Unit> undone = await _undoAdd(event.added.entry).run();
    undone.mapLeft(_logFailure('habits.undo_failed'));
    await _load(emit);
  }

  // why: the type only. A failure's message can carry a row's text, and nothing about a habit
  // may reach the log (NFR-3, BR-17).
  static void Function(Failure) _logFailure(String tag) =>
      (Failure failure) => AppLogger.log(tag: tag, data: <String, Object?>{'type': failure.runtimeType.toString()});

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
