import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/usecases/use_case.dart';
import 'delete_everything_event.dart';
import 'delete_everything_state.dart';

/// Owns the *Delete everything* page's delete (SPEC FR-SE-4 AC-8), driven by the hold key.
class DeleteEverythingBloc extends Bloc<DeleteEverythingEvent, DeleteEverythingState> {
  DeleteEverythingBloc({required this._deleteEverything, required this._haptics}) : super(const DeleteEverythingIdle()) {
    // why: a second confirm while the wipe runs is dropped, so it never runs twice.
    on<DeleteEverythingConfirmed>(_onConfirmed, transformer: droppable());
  }

  final UseCase<Unit, NoParams> _deleteEverything;
  final Haptics _haptics;

  Future<void> _onConfirmed(DeleteEverythingConfirmed event, Emitter<DeleteEverythingState> emit) async {
    final int failures = switch (state) {
      DeleteEverythingIdle(:final int failures) => failures,
      DeleteEverythingWorking() || DeleteEverythingDone() => 0,
    };
    emit(const DeleteEverythingWorking());
    final Either<Failure, Unit> done = await _deleteEverything(const NoParams()).run();
    await done.match(
      (Failure failure) async {
        AppLogger.log(tag: 'delete_everything.failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
        await _haptics.reject();
        emit(DeleteEverythingIdle(failures: failures + 1));
      },
      (Unit _) async => emit(const DeleteEverythingDone()),
    );
  }
}
