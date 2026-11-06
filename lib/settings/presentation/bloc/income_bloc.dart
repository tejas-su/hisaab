import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import 'income_event.dart';
import 'income_state.dart';

/// Owns the income shown by Settings' *Money coming in* row (SPEC FR-SE-1). Settings adds
/// [IncomeLoadRequested] when it opens; every rule or entry change reloads it, so the row and the
/// next sheet always show what is saved.
class IncomeBloc extends Bloc<IncomeEvent, IncomeState> {
  IncomeBloc({required this._getIncome, required RecurringRepository recurring, required LedgerRepository ledger})
    : super(const IncomeLoading()) {
    // why: a newer load cancels an older one still reading, so a stale income never lands last.
    on<IncomeLoadRequested>(_onLoadRequested, transformer: restartable());
    _ruleChanges = recurring.changes.listen((void _) => add(const IncomeLoadRequested()));
    // why: *Change this month too* edits the latest pay, which the next sheet must show.
    _entryChanges = ledger.changes.listen((void _) => add(const IncomeLoadRequested()));
  }

  final GetIncome _getIncome;
  late final StreamSubscription<void> _ruleChanges;
  late final StreamSubscription<void> _entryChanges;

  Future<void> _onLoadRequested(IncomeLoadRequested event, Emitter<IncomeState> emit) async {
    final Either<Failure, Income> loaded = await _getIncome(const NoParams()).run();
    emit(
      loaded.match((Failure failure) {
        AppLogger.log(tag: 'income.load_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
        return IncomeFailed(failure);
      }, IncomeReady.new),
    );
  }

  @override
  Future<void> close() async {
    await _ruleChanges.cancel();
    await _entryChanges.cancel();
    return super.close();
  }
}
