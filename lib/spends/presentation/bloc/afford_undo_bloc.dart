import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../domain/usecase/undo_start_saving.dart';
import 'afford_undo_event.dart';
import 'afford_undo_state.dart';

/// Offers and performs the Undo of *Start saving* (SPEC FR-SP-9 AC-6, E164). The sheet's own
/// bloc closes with the sheet, so this small bloc lives with Spends, like `FixUndoBloc` (D179).
///
/// Driven by whoever opens the sheet, which passes its outcome on as [AffordUndoOffered], and by
/// the snackbar's Undo.
class AffordUndoBloc extends Bloc<AffordUndoEvent, AffordUndoState> {
  AffordUndoBloc({required this._undo, required this._haptics}) : super(const AffordUndoIdle()) {
    on<AffordUndoOffered>((AffordUndoOffered event, Emitter<AffordUndoState> emit) => emit(AffordUndoShown(event.started)));
    // why: a second Undo while the first is written is dropped, so a saving is never restored twice.
    on<AffordUndoRequested>(_onUndoRequested, transformer: droppable());
  }

  final UndoStartSaving _undo;
  final Haptics _haptics;

  Future<void> _onUndoRequested(AffordUndoRequested event, Emitter<AffordUndoState> emit) async {
    final Either<Failure, Unit> undone = await _undo(event.started).run();
    undone.match(
      (Failure failure) {
        AppLogger.log(tag: 'afford.undo_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
        unawaited(_haptics.reject());
        emit(const AffordUndoFailed());
      },
      (Unit _) {
        unawaited(_haptics.tick());
        emit(const AffordUndoDone());
      },
    );
  }
}
