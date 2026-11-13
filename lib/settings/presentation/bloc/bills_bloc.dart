import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/money/money.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import 'bills_event.dart';
import 'bills_state.dart';

/// Owns the Fixed bills list, or the Savings list when [kind] is *Saved* (SPEC FR-SE-1, D120).
/// Driven by [BillsLoadRequested] from the page and by every rule change through
/// [RecurringRepository.changes]; a savings list also reloads on every ledger write, so its
/// "put in" total stays current. The page adds [BillsDeleteRequested] and [BillsUndoRequested].
class BillsBloc extends Bloc<BillsEvent, BillsState> {
  BillsBloc({
    required this._getBills,
    required this._deleteBill,
    required this._restoreBill,
    required RecurringRepository recurring,
    required this._haptics,
    required this._getSavedTotal,
    required this._ledger,
    this._deleteEntry,
    this._getSetAside,
    this.kind = EntryKind.spent,
  }) : super(const BillsLoading()) {
    // why: a newer load cancels an older one still reading, so stale bills never land last.
    on<BillsLoadRequested>((BillsLoadRequested event, Emitter<BillsState> emit) => _load(emit), transformer: restartable());
    on<BillsDeleteRequested>(_onDeleteRequested);
    on<BillsUndoRequested>(_onUndoRequested);
    on<BillsUsedDone>(_onUsedDone);
    on<BillsUsedUndoRequested>(_onUsedUndoRequested);
    on<BillsSwipeThresholdReached>((BillsSwipeThresholdReached event, Emitter<BillsState> emit) => unawaited(_haptics.threshold()));
    _changes = recurring.changes.listen((void _) => add(const BillsLoadRequested()));
    _entryChanges = _ledger.changes.listen((void _) {
      if (kind == EntryKind.saved) {
        add(const BillsLoadRequested());
      }
    });
  }

  /// Which list this is: *Spent* for the fixed bills, *Saved* for the savings.
  final EntryKind kind;
  final GetSavedTotal _getSavedTotal;
  final LedgerRepository _ledger;

  /// Deletes a *Used* entry for its Undo; null for a list that offers none.
  final DeleteEntry? _deleteEntry;

  /// Reads what each saving has set aside; used only by a savings list, and only when given.
  final GetSetAside? _getSetAside;
  late final StreamSubscription<void> _entryChanges;

  final GetBills _getBills;
  final DeleteBill _deleteBill;
  final RestoreBill _restoreBill;
  final Haptics _haptics;
  late final StreamSubscription<void> _changes;

  /// Loads the rules of [kind], soonest first, and for savings the total put in so far and what
  /// each has set aside.
  Future<void> _load(Emitter<BillsState> emit) async {
    final Either<Failure, BillsReady> loaded = await _getBills(kind)
        .flatMap(
          (List<RecurringRule> bills) => _savedTotal().flatMap(
            (Option<SavedTotal> saved) => _setAside().map(
              (Option<SetAsideSummary> setAside) => BillsReady(bills: bills, saved: saved, setAside: setAside),
            ),
          ),
        )
        .run();
    emit(loaded.match((Failure failure) {
      _log('bills.load_failed', failure);
      return BillsFailed(failure);
    }, (BillsReady ready) => ready));
  }

  TaskEither<Failure, Option<SavedTotal>> _savedTotal() => kind == EntryKind.saved
      ? _getSavedTotal(const NoParams())
      : TaskEither<Failure, Option<SavedTotal>>.right(const Option<SavedTotal>.none());

  TaskEither<Failure, Option<SetAsideSummary>> _setAside() {
    final GetSetAside? getSetAside = _getSetAside;
    return kind == EntryKind.saved && getSetAside != null
        ? getSetAside(const NoParams()).map(Option<SetAsideSummary>.of)
        : TaskEither<Failure, Option<SetAsideSummary>>.right(const Option<SetAsideSummary>.none());
  }

  // why: the row leaves the list in the first emit, before the delete is written, so the
  // Dismissible that was swiped away is gone from the tree by the next frame.
  Future<void> _onDeleteRequested(BillsDeleteRequested event, Emitter<BillsState> emit) async {
    final BillsState current = state;
    if (current is! BillsReady) {
      return;
    }
    final RecurringRule bill = event.bill;
    final bool keepsHistory = await _hadPutIn(bill);
    emit(current.copyWith(bills: current.bills.where((RecurringRule b) => b.id != bill.id).toList(), saved: current.saved));
    final Either<Failure, Unit> deleted = await _deleteBill(bill.id).run();
    await deleted.match(
      (Failure failure) {
        _log('bills.delete_failed', failure);
        return _load(emit);
      },
      (Unit _) async {
        final BillsState latest = state;
        if (latest is BillsReady) {
          emit(latest.copyWith(undo: Option<RecurringRule>.of(bill), saved: latest.saved, undoKeepsHistory: keepsHistory));
        }
      },
    );
  }

  // why: AC-Y10 says what stays only for a saving that has had a put-in; read before the delete,
  // since the reload that follows it no longer lists the rule.
  Future<bool> _hadPutIn(RecurringRule bill) async {
    if (bill.kind != EntryKind.saved) {
      return false;
    }
    final Either<Failure, SavingTotals> totals = await _ledger.savingTotals().run();
    return totals.match((Failure _) => false, (SavingTotals t) => (t.bySaving[bill.id]?.putIn ?? Money.zero) > Money.zero);
  }

  /// Offers Undo for a *Used* save made on a saving's sheet from this list (AC-Y9).
  void _onUsedDone(BillsUsedDone event, Emitter<BillsState> emit) {
    final BillsState current = state;
    if (current is BillsReady) {
      emit(current.copyWith(usedUndo: Option<UsedOutcome>.of(event.outcome), saved: current.saved));
    }
  }

  /// Deletes the *Used* entry, so the money is set aside again; the ledger stream reloads the list.
  Future<void> _onUsedUndoRequested(BillsUsedUndoRequested event, Emitter<BillsState> emit) async {
    final DeleteEntry? deleteEntry = _deleteEntry;
    if (deleteEntry == null) {
      return;
    }
    final Either<Failure, Entry> deleted = await deleteEntry(event.entry.id).run();
    deleted.mapLeft((Failure failure) => _log('bills.used_undo_failed', failure));
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
    await _entryChanges.cancel();
    return super.close();
  }
}
