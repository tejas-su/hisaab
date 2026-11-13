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
import 'used_event.dart';
import 'used_state.dart';

/// Owns the *Used some of it* keypad of a saving's sheet (BR-19): reads what is set aside, takes
/// digits up to it and saves a *Used* entry. Driven by the sheet page (keys, *All of it*, Save, and
/// back), which connects it to the sheet's own bloc with a listener.
class UsedBloc extends Bloc<UsedEvent, UsedState> {
  UsedBloc({
    required this._getSetAside,
    required this._useFromSavings,
    required this._haptics,
  }) : super(const UsedLoading()) {
    // why: a newer load cancels an older one still reading, so a stale figure never lands last.
    on<UsedLoadRequested>(_onLoad, transformer: restartable());
    on<UsedKeyPressed>((UsedKeyPressed event, Emitter<UsedState> emit) => _typeKey(emit, event.key));
    on<UsedBackspacePressed>(
      (UsedBackspacePressed event, Emitter<UsedState> emit) =>
          _edit(emit, (int rupees) => Option<int>.of(AmountInput.backspace(rupees))),
    );
    on<UsedCleared>((UsedCleared event, Emitter<UsedState> emit) => _edit(emit, (int _) => const Option<int>.of(0)));
    on<UsedAllPressed>(_onAllPressed);
    // why: a second Save while the first is in flight must not write the use twice.
    on<UsedSavePressed>(_onSave, transformer: droppable());
    on<UsedReset>(_onReset);
  }

  final GetSetAside _getSetAside;
  final UseFromSavings _useFromSavings;
  final Haptics _haptics;

  Future<void> _onLoad(UsedLoadRequested event, Emitter<UsedState> emit) async {
    final Either<Failure, int> read = await _setAsideRupees(event.saving).run();
    emit(read.match((Failure failure) {
      _log('used.load_failed', failure);
      return UsedFailed(failure);
    }, (int rupees) => UsedReady(saving: event.saving, setAsideRupees: rupees)));
  }

  TaskEither<Failure, int> _setAsideRupees(RecurringRule saving) => _getSetAside(const NoParams()).map(
        (SetAsideSummary summary) => summary.perSaving[saving.id]?.floorMajor ?? 0,
      );

  // why: the first digit after *All of it* replaces the filled amount (FR-AD-8).
  void _typeKey(Emitter<UsedState> emit, String key) {
    final UsedState current = state;
    if (current is! UsedReady) {
      return;
    }
    _edit(emit, (int rupees) => AmountInput.append(current.replaceNext ? 0 : rupees, key));
  }

  // why: a key that would pass what is set aside is refused like a 10th digit, so the cap is felt
  // on the keypad rather than told after Save (E94).
  void _edit(Emitter<UsedState> emit, Option<int> Function(int rupees) edit) {
    final UsedState current = state;
    if (current is! UsedReady || current.writing) {
      return;
    }
    edit(current.rupees).filter((int rupees) => rupees <= current.setAsideRupees).match(
      () {
        unawaited(_haptics.reject());
        emit(current.copyWith(rejections: current.rejections + 1, capShown: true));
      },
      (int rupees) {
        unawaited(_haptics.tick());
        emit(current.copyWith(rupees: rupees, capShown: false, replaceNext: false));
      },
    );
  }

  void _onAllPressed(UsedAllPressed event, Emitter<UsedState> emit) {
    final UsedState current = state;
    if (current is! UsedReady || current.writing || current.nothingToUse) {
      return;
    }
    unawaited(_haptics.tick());
    emit(
      current.allSelected
          ? current.copyWith(rupees: 0, capShown: false, replaceNext: false)
          : current.copyWith(rupees: current.setAsideRupees, capShown: false, replaceNext: true),
    );
  }

  Future<void> _onSave(UsedSavePressed event, Emitter<UsedState> emit) async {
    final UsedState current = state;
    if (current is! UsedReady || !current.canSave) {
      return;
    }
    emit(current.copyWith(writing: true));
    final Either<Failure, Entry> saved = await _useFromSavings(
      UseFromSavingsParams(saving: current.saving, amount: Money.fromMajor(current.rupees)),
    ).run();
    await saved.match(
      (Failure failure) => _onSaveFailed(emit, current, failure),
      (Entry entry) async {
        unawaited(_haptics.success());
        emit(UsedDone(UsedOutcome(entry: entry, saving: current.saving)));
      },
    );
  }

  // why: a refusal means the set-aside fell behind the sheet (a put-in was deleted), so the figure
  // is read again and the sheet stays open with the cap line (E99).
  Future<void> _onSaveFailed(Emitter<UsedState> emit, UsedReady current, Failure failure) async {
    _log('used.save_failed', failure);
    unawaited(_haptics.reject());
    if (failure is! UsedTooMuchFailure) {
      emit(current.copyWith(writing: false, saveFailed: true));
      return;
    }
    final Either<Failure, int> refreshed = await _setAsideRupees(current.saving).run();
    emit(
      current.copyWith(
        writing: false,
        setAsideRupees: refreshed.getOrElse((Failure _) => current.setAsideRupees),
        rejections: current.rejections + 1,
        capShown: true,
      ),
    );
  }

  void _onReset(UsedReset event, Emitter<UsedState> emit) {
    final UsedState current = state;
    if (current is! UsedReady || current.writing) {
      return;
    }
    emit(current.copyWith(rupees: 0, capShown: false, replaceNext: false));
  }

  static void _log(String tag, Failure failure) =>
      AppLogger.log(tag: tag, data: <String, Object?>{'type': failure.runtimeType.toString()});
}
