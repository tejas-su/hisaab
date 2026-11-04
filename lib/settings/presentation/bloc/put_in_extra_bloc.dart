import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/money/amount_input.dart';
import '../../../core/money/money.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import 'put_in_extra_event.dart';
import 'put_in_extra_state.dart';

/// Owns the *Put in extra* keypad (D120): loads today's summary, takes digits up to what is
/// left, previews the effect on later days and saves a one-off *Saved* entry. Driven by the
/// [PutInSheet] page's keys and Save.
class PutInExtraBloc extends Bloc<PutInExtraEvent, PutInExtraState> {
  PutInExtraBloc({
    required this._getCycleSummary,
    required this._putInExtra,
    required this._haptics,
  }) : super(const PutInExtraLoading()) {
    on<PutInExtraLoadRequested>(_onLoad, transformer: restartable());
    on<PutInExtraKeyPressed>(
      (PutInExtraKeyPressed event, Emitter<PutInExtraState> emit) =>
          _edit(emit, (int rupees) => AmountInput.append(rupees, event.key)),
    );
    on<PutInExtraBackspacePressed>(
      (PutInExtraBackspacePressed event, Emitter<PutInExtraState> emit) =>
          _edit(emit, (int rupees) => Option<int>.of(AmountInput.backspace(rupees))),
    );
    on<PutInExtraCleared>((PutInExtraCleared event, Emitter<PutInExtraState> emit) => _edit(emit, (int _) => const Option<int>.of(0)));
    // why: a second Save while the first is in flight must not put the money in twice.
    on<PutInExtraSavePressed>(_onSave, transformer: droppable());
  }

  final GetCycleSummary _getCycleSummary;
  final PutInExtra _putInExtra;
  final Haptics _haptics;

  Future<void> _onLoad(PutInExtraLoadRequested event, Emitter<PutInExtraState> emit) async {
    final Either<Failure, CycleSummary> loaded = await _getCycleSummary(const NoParams()).run();
    emit(loaded.match((Failure failure) {
      _log('put_in.load_failed', failure);
      return PutInExtraFailed(failure);
    }, (CycleSummary summary) => PutInExtraReady(summary: summary)));
  }

  // why: a key that would go past what is left is refused like a 10th digit, so the cap is felt
  // on the keypad rather than told after Save.
  void _edit(Emitter<PutInExtraState> emit, Option<int> Function(int rupees) edit) {
    final PutInExtraState current = state;
    if (current is! PutInExtraReady || current.saving) {
      return;
    }
    edit(current.rupees).filter((int rupees) => rupees <= current.roomRupees).match(
      () {
        unawaited(_haptics.reject());
        emit(current.copyWith(rejections: current.rejections + 1));
      },
      (int rupees) {
        unawaited(_haptics.tick());
        emit(current.copyWith(rupees: rupees));
      },
    );
  }

  Future<void> _onSave(PutInExtraSavePressed event, Emitter<PutInExtraState> emit) async {
    final PutInExtraState current = state;
    if (current is! PutInExtraReady || current.rupees == 0 || current.nothingLeft) {
      return;
    }
    emit(current.copyWith(saving: true));
    final Either<Failure, Entry> saved = await _putInExtra(Money.fromMajor(current.rupees)).run();
    saved.match(
      (Failure failure) {
        _log('put_in.save_failed', failure);
        unawaited(_haptics.reject());
        emit(current.copyWith(saveFailed: true));
      },
      (Entry _) {
        unawaited(_haptics.success());
        emit(const PutInExtraDone());
      },
    );
  }

  static void _log(String tag, Failure failure) =>
      AppLogger.log(tag: tag, data: <String, Object?>{'type': failure.runtimeType.toString()});
}
