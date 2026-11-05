import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/money/amount_input.dart';
import '../../../core/money/money.dart';
import '../../../ledger/ledger.dart';
import 'bill_amount_event.dart';
import 'bill_amount_state.dart';

/// Owns the bill amount keypad for one waiting [Occurrence] (D123): prefilled with its estimate,
/// it enters the amount on Save or skips the month. Driven by the [BillAmountSheet]'s keys.
class BillAmountBloc extends Bloc<BillAmountEvent, BillAmountState> {
  BillAmountBloc({
    required this._occurrence,
    required this._getLastAmount,
    required this._enter,
    required this._skip,
    required this._haptics,
  }) : super(const BillAmountLoading()) {
    on<BillAmountLoadRequested>(_onLoad, transformer: restartable());
    on<BillAmountKeyPressed>(
      (BillAmountKeyPressed event, Emitter<BillAmountState> emit) =>
          _edit(emit, (int rupees, bool fresh) => AmountInput.append(fresh ? 0 : rupees, event.key)),
    );
    on<BillAmountBackspacePressed>(
      (BillAmountBackspacePressed event, Emitter<BillAmountState> emit) =>
          _edit(emit, (int rupees, bool _) => Option<int>.of(AmountInput.backspace(rupees))),
    );
    on<BillAmountCleared>((BillAmountCleared event, Emitter<BillAmountState> emit) => _edit(emit, (int _, bool _) => const Option<int>.of(0)));
    // why: a second tap while the first write is in flight must not enter or skip twice.
    on<BillAmountSavePressed>(_onSave, transformer: droppable());
    on<BillAmountSkipPressed>(_onSkip, transformer: droppable());
  }

  final Occurrence _occurrence;
  final GetLastBillAmount _getLastAmount;
  final EnterBillAmount _enter;
  final SkipBillOccurrence _skip;
  final Haptics _haptics;

  // why: the history only picks the caption; if it can't be read, the keypad still opens.
  Future<void> _onLoad(BillAmountLoadRequested event, Emitter<BillAmountState> emit) async {
    final Either<Failure, Option<Money>> last = await _getLastAmount(_occurrence.rule).run();
    emit(BillAmountEditing(
      occurrence: _occurrence,
      rupees: _occurrence.rule.amount.floorMajor,
      lastTime: last.getOrElse((Failure failure) {
        _log('bills.last_amount_failed', failure);
        return const Option<Money>.none();
      }),
    ));
  }

  void _edit(Emitter<BillAmountState> emit, Option<int> Function(int rupees, bool fresh) edit) {
    final BillAmountState current = state;
    if (current is! BillAmountEditing || current.saving) {
      return;
    }
    edit(current.rupees, current.fresh).match(
      () {
        unawaited(_haptics.reject());
        emit(current.copyWith(rejections: current.rejections + 1));
      },
      (int rupees) {
        unawaited(_haptics.tick());
        emit(current.copyWith(rupees: rupees, fresh: false));
      },
    );
  }

  Future<void> _onSave(BillAmountSavePressed event, Emitter<BillAmountState> emit) async {
    final BillAmountState current = state;
    if (current is! BillAmountEditing || current.rupees == 0) {
      return;
    }
    emit(current.copyWith(saving: true));
    final Either<Failure, BillAmountEntered> entered =
        await _enter(EnterBillAmountParams(occurrence: _occurrence, amount: Money.fromMajor(current.rupees))).run();
    _finish(emit, current, entered.map(BillAmountWasEntered.new));
  }

  Future<void> _onSkip(BillAmountSkipPressed event, Emitter<BillAmountState> emit) async {
    final BillAmountState current = state;
    if (current is! BillAmountEditing) {
      return;
    }
    emit(current.copyWith(saving: true));
    final Either<Failure, BillSkip> skipped = await _skip(_occurrence).run();
    _finish(emit, current, skipped.map((BillSkip skip) => BillAmountWasSkipped(occurrence: _occurrence, skip: skip)));
  }

  void _finish(Emitter<BillAmountState> emit, BillAmountEditing form, Either<Failure, BillAmountOutcome> result) => result.match(
        (Failure failure) {
          _log('bills.amount_save_failed', failure);
          unawaited(_haptics.reject());
          emit(form.copyWith(saveFailed: true));
        },
        (BillAmountOutcome outcome) {
          unawaited(_haptics.tick());
          emit(BillAmountDone(outcome));
        },
      );

  static void _log(String tag, Failure failure) =>
      AppLogger.log(tag: tag, data: <String, Object?>{'type': failure.runtimeType.toString()});
}
