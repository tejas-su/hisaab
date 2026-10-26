import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import 'bills_state.dart';

/// Owns the Fixed bills list (SPEC FR-SE-1). Driven by [load] and by every rule change through
/// [RecurringRepository.changes]; the page calls [delete] and [undo].
class BillsCubit extends Cubit<BillsState> {
  BillsCubit({
    required this._getBills,
    required this._deleteBill,
    required this._restoreBill,
    required RecurringRepository recurring,
    required this._haptics,
  }) : super(const BillsLoading()) {
    _changes = recurring.changes.listen((void _) => load());
  }

  final GetBills _getBills;
  final DeleteBill _deleteBill;
  final RestoreBill _restoreBill;
  final Haptics _haptics;
  late final StreamSubscription<void> _changes;

  /// Loads the bills, soonest first.
  Future<void> load() async {
    final Either<Failure, List<RecurringRule>> loaded = await _getBills(const NoParams()).run();
    if (isClosed) {
      return;
    }
    emit(loaded.match((Failure failure) {
      _log('bills.load_failed', failure);
      return BillsFailed(failure);
    }, (List<RecurringRule> bills) => BillsReady(bills: bills)));
  }

  /// Deletes [bill] at once (the row disappears synchronously) and then offers Undo.
  Future<void> delete(RecurringRule bill) async {
    final BillsState current = state;
    if (current is! BillsReady) {
      return;
    }
    emit(current.copyWith(bills: current.bills.where((RecurringRule b) => b.id != bill.id).toList()));
    final Either<Failure, Unit> deleted = await _deleteBill(bill.id).run();
    if (isClosed) {
      return;
    }
    await deleted.match(
      (Failure failure) {
        _log('bills.delete_failed', failure);
        return load();
      },
      (Unit _) async {
        final BillsState latest = state;
        if (latest is BillsReady) {
          emit(latest.copyWith(undo: Option<RecurringRule>.of(bill)));
        }
      },
    );
  }

  /// Brings back a deleted [bill]; the change stream reloads the list.
  Future<void> undo(RecurringRule bill) async {
    final Either<Failure, Unit> restored = await _restoreBill(bill.id).run();
    restored.mapLeft((Failure failure) => _log('bills.undo_failed', failure));
  }

  /// A row's swipe crossed the delete threshold.
  void swipeThresholdReached() => unawaited(_haptics.threshold());

  static void _log(String tag, Failure failure) =>
      AppLogger.log(tag: tag, data: <String, Object?>{'type': failure.runtimeType.toString()});

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
