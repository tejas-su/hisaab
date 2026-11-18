import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/usecases/use_case.dart';
import '../../domain/entities/nudge_switch.dart';
import '../../domain/usecase/answer_nudge.dart';
import '../../domain/usecase/get_nudge_switch.dart';
import 'nudge_row_event.dart';
import 'nudge_row_state.dart';

/// Owns Settings' *Daily nudge* switch (SPEC FR-SE-7): its position, the refusal line, and writing
/// the answer when it is flipped. Driven by the Settings page, which re-arms the nudges whenever
/// [NudgeRowReady.changes] grows.
class NudgeRowBloc extends Bloc<NudgeRowEvent, NudgeRowState> {
  NudgeRowBloc({required this._getSwitch, required this._answer, required this._haptics}) : super(const NudgeRowLoading()) {
    on<NudgeRowLoadRequested>(_onLoadRequested, transformer: restartable());
    // why: a second flip while Android's permission prompt is up must not ask or write twice.
    on<NudgeRowToggled>(_onToggled, transformer: droppable());
  }

  final GetNudgeSwitch _getSwitch;
  final AnswerNudge _answer;
  final Haptics _haptics;

  Future<void> _onLoadRequested(NudgeRowLoadRequested event, Emitter<NudgeRowState> emit) async {
    final Either<Failure, NudgeSwitch> read = await _getSwitch(const NoParams()).run();
    read.match(
      // why: a failed read leaves the switch off, which also arms nothing.
      (Failure failure) {
        _logged(failure, 'nudge_row.read_failed');
        emit(const NudgeRowReady(on: false));
      },
      (NudgeSwitch found) => emit(NudgeRowReady(on: found.on, refused: found.blocked)),
    );
  }

  Future<void> _onToggled(NudgeRowToggled event, Emitter<NudgeRowState> emit) async {
    final NudgeRowState before = state;
    if (before is! NudgeRowReady) {
      return;
    }
    await _haptics.tick();
    final Either<Failure, bool> answered = await _answer(event.on).run();
    answered.match(
      (Failure failure) => _logged(failure, 'nudge_row.write_failed'),
      (bool on) => emit(NudgeRowReady(on: on, refused: event.on && !on, changes: before.changes + 1)),
    );
  }

  // why: the type only; nothing about a habit may reach the log (NFR-3).
  static bool _logged(Failure failure, String tag) {
    AppLogger.log(tag: tag, data: <String, Object?>{'type': failure.runtimeType.toString()});
    return false;
  }
}
