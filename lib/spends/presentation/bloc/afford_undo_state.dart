import 'package:equatable/equatable.dart';

import '../../domain/entities/saving_started.dart';

/// What Spends shows for a *Start saving* Undo.
sealed class AffordUndoState extends Equatable {
  const AffordUndoState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Nothing to undo.
final class AffordUndoIdle extends AffordUndoState {
  const AffordUndoIdle();
}

/// A saving was started: Spends shows "Saving ₹5,000 a month for Mac" with *Undo*.
final class AffordUndoShown extends AffordUndoState {
  const AffordUndoShown(this.started);

  final SavingStarted started;

  @override
  List<Object?> get props => <Object?>[started];
}

/// The saving was undone: Spends announces "Undone.".
final class AffordUndoDone extends AffordUndoState {
  const AffordUndoDone();
}

/// The Undo could not be written; Spends says "Couldn't save. Try again." and the saving stays.
final class AffordUndoFailed extends AffordUndoState {
  const AffordUndoFailed();
}
