import 'package:equatable/equatable.dart';

import '../../domain/entities/saving_started.dart';

/// What happens around the Undo that *Start saving* offers on Spends (SPEC FR-SP-9 AC-6).
sealed class AffordUndoEvent extends Equatable {
  const AffordUndoEvent();
}

/// The *Can I afford it?* sheet closed after writing [started]; offer Undo for it.
final class AffordUndoOffered extends AffordUndoEvent {
  const AffordUndoOffered(this.started);

  final SavingStarted started;

  @override
  List<Object?> get props => <Object?>[started];
}

/// The user tapped Undo on the snackbar for [started].
final class AffordUndoRequested extends AffordUndoEvent {
  const AffordUndoRequested(this.started);

  final SavingStarted started;

  @override
  List<Object?> get props => <Object?>[started];
}
