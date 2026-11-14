import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../ledger/ledger.dart';
import 'fix_undo_event.dart';
import 'fix_undo_state.dart';

/// Offers and performs the Undo of a fix made from Settings. Home's snackbar host sits under the
/// Settings route and would never show it, so this small bloc lives in that route (P4, C12).
///
/// Driven by the page, which connects the sheet's outcome to [FixUndoOffered] with a listener.
class FixUndoBloc extends Bloc<FixUndoEvent, FixUndoState> {
  FixUndoBloc({required this._deleteEntry, required this._haptics}) : super(const FixUndoIdle()) {
    on<FixUndoOffered>((FixUndoOffered event, Emitter<FixUndoState> emit) => emit(FixUndoShown(event.outcome)));
    on<FixUndoRequested>(_onUndoRequested);
  }

  final DeleteEntry _deleteEntry;
  final Haptics _haptics;

  // why: deleting the entry reverts the number exactly, since it was computed and never stored (BR-18).
  Future<void> _onUndoRequested(FixUndoRequested event, Emitter<FixUndoState> emit) async {
    final Either<Failure, Entry> deleted = await _deleteEntry(event.outcome.entry.id).run();
    deleted.match(
      (Failure failure) => AppLogger.log(tag: 'fix.undo_failed', data: <String, Object?>{'type': failure.runtimeType.toString()}),
      (Entry _) {
        unawaited(_haptics.tick());
        emit(const FixUndoDone());
      },
    );
  }
}
