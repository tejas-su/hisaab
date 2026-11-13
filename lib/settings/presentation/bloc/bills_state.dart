import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../ledger/ledger.dart';

/// What the Fixed bills screen shows.
sealed class BillsState extends Equatable {
  const BillsState();

  @override
  List<Object?> get props => <Object?>[];
}

/// First load; nothing to show yet.
final class BillsLoading extends BillsState {
  const BillsLoading();
}

/// The bills (or savings), soonest first. [undo] holds one just deleted, so the page can offer
/// Undo once; [saved] is the savings list's "put in" total, [None] for bills or before any save;
/// [setAside] is what each saving still has set aside (BR-19), [None] for bills; [usedUndo] holds a
/// *Used* save just made, so the page can offer Undo once (AC-Y9); [undoKeepsHistory] says the saving
/// in [undo] has had a put-in, so its Undo bar says what stays (AC-Y10).
final class BillsReady extends BillsState {
  const BillsReady({
    required this.bills,
    this.undo = const Option<RecurringRule>.none(),
    this.saved = const Option<SavedTotal>.none(),
    this.setAside = const Option<SetAsideSummary>.none(),
    this.usedUndo = const Option<UsedOutcome>.none(),
    this.undoKeepsHistory = false,
  });

  final List<RecurringRule> bills;
  final Option<RecurringRule> undo;
  final Option<SavedTotal> saved;
  final Option<SetAsideSummary> setAside;
  final Option<UsedOutcome> usedUndo;
  final bool undoKeepsHistory;

  /// Returns a copy with the given fields replaced; [undo] and [saved] reset unless passed,
  /// [setAside] is kept unless passed; [usedUndo] and [undoKeepsHistory] reset unless passed.
  BillsReady copyWith({
    List<RecurringRule>? bills,
    Option<RecurringRule> undo = const Option<RecurringRule>.none(),
    Option<SavedTotal> saved = const Option<SavedTotal>.none(),
    Option<SetAsideSummary>? setAside,
    Option<UsedOutcome> usedUndo = const Option<UsedOutcome>.none(),
    bool undoKeepsHistory = false,
  }) =>
      BillsReady(
        bills: bills ?? this.bills,
        undo: undo,
        saved: saved,
        setAside: setAside ?? this.setAside,
        usedUndo: usedUndo,
        undoKeepsHistory: undoKeepsHistory,
      );

  @override
  List<Object?> get props => <Object?>[bills, undo, saved, setAside, usedUndo, undoKeepsHistory];
}

/// Loading failed; a quiet message with Try again.
final class BillsFailed extends BillsState {
  const BillsFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}
