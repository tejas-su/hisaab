import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../ledger/ledger.dart';
import 'bills_event.dart';
import 'bills_state.dart';

/// Owns the Fixed bills list (SPEC FR-SE-1). Driven by [BillsLoadRequested] from the page and
/// by every rule change through [RecurringRepository.changes]; the page adds
/// [BillsDeleteRequested] and [BillsUndoRequested].
class BillsBloc extends Bloc<BillsEvent, BillsState> {
  BillsBloc({
    required this._getBills,
    required this._deleteBill,
    required this._restoreBill,
    required RecurringRepository recurring,
    required this._haptics,
  }) : super(const BillsLoading()) {
    // why: a newer load cancels an older one still reading, so stale bills never land last.
    on<BillsLoadRequested>((BillsLoadRequested event, Emitter<BillsState> emit) => _load(emit), transformer: restartable());
    on<BillsDeleteRequested>(_onDeleteRequested);
    on<BillsUndoRequested>(_onUndoRequested);
    on<BillsSwipeThresholdReached>((BillsSwipeThresholdReached event, Emitter<BillsState> emit) => unawaited(_haptics.threshold()));
    _changes = recurring.changes.listen((void _) => add(const BillsLoadRequested()));
  }

  final GetBills _getBills;
  final DeleteBill _deleteBill;
  final RestoreBill _restoreBill;
  final Haptics _haptics;
  late final StreamSubscription<void> _changes;

  /// Loads the bills, soonest first.
  Future<void> _load(Emitter<BillsState> emit) async {
    final Either<Failure, List<RecurringRule>> loaded = await _getBills(EntryKind.spent).run();
    emit(loaded.match((Failure failure) {
      _log('bills.load_failed', failure);
      return BillsFailed(failure);
    }, (List<RecurringRule> bills) => BillsReady(bills: bills)));
  }

  // why: the row leaves the list in the first emit, before the delete is written, so the
  // Dismissible that was swiped away is gone from the tree by the next frame.
  Future<void> _onDeleteRequested(BillsDeleteRequested event, Emitter<BillsState> emit) async {
    final BillsState current = state;
    if (current is! BillsReady) {
      return;
    }
    final RecurringRule bill = event.bill;
    emit(current.copyWith(bills: current.bills.where((RecurringRule b) => b.id != bill.id).toList()));
    final Either<Failure, Unit> deleted = await _deleteBill(bill.id).run();
    await deleted.match(
      (Failure failure) {
        _log('bills.delete_failed', failure);
        return _load(emit);
      },
      (Unit _) async {
        final BillsState latest = state;
        if (latest is BillsReady) {
          emit(latest.copyWith(undo: Option<RecurringRule>.of(bill)));
        }
      },
    );
  }

  /// Brings back a deleted bill; the change stream reloads the list.
  Future<void> _onUndoRequested(BillsUndoRequested event, Emitter<BillsState> emit) async {
    final Either<Failure, Unit> restored = await _restoreBill(event.bill.id).run();
    restored.mapLeft((Failure failure) => _log('bills.undo_failed', failure));
  }

  static void _log(String tag, Failure failure) =>
      AppLogger.log(tag: tag, data: <String, Object?>{'type': failure.runtimeType.toString()});

  @override
  Future<void> close() async {
    await _changes.cancel();
    return super.close();
  }
}
