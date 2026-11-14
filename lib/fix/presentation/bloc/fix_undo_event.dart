import 'package:equatable/equatable.dart';

import '../../../ledger/ledger.dart';

/// What happens around the Undo a fix offers on Settings (SPEC FR-FX-5 AC-5, D179).
sealed class FixUndoEvent extends Equatable {
  const FixUndoEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The *Fix my number* sheet opened from Settings wrote [outcome]; offer Undo for it.
final class FixUndoOffered extends FixUndoEvent {
  const FixUndoOffered(this.outcome);

  final FixOutcome outcome;

  @override
  List<Object?> get props => <Object?>[outcome];
}

/// The user tapped Undo on the snackbar for [outcome].
final class FixUndoRequested extends FixUndoEvent {
  const FixUndoRequested(this.outcome);

  final FixOutcome outcome;

  @override
  List<Object?> get props => <Object?>[outcome];
}
