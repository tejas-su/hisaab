import 'package:equatable/equatable.dart';

import '../../../ledger/ledger.dart';

/// What the Settings page shows for a fix's Undo.
sealed class FixUndoState extends Equatable {
  const FixUndoState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Nothing to undo.
final class FixUndoIdle extends FixUndoState {
  const FixUndoIdle();
}

/// A fix was written: the page shows "Fixed. Safe to spend today: ₹963." with *Undo*.
final class FixUndoShown extends FixUndoState {
  const FixUndoShown(this.outcome);

  final FixOutcome outcome;

  @override
  List<Object?> get props => <Object?>[outcome];
}

/// The fix was undone: the page announces "Undone.".
final class FixUndoDone extends FixUndoState {
  const FixUndoDone();
}
