import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import '../entities/suggestion_state.dart';
import '../repository/suggestion_state_repository.dart';
import '../suggestion_gate.dart';

/// Undoes a one-tap add from the *your usual* pill: deletes the entry and quiets its category
/// until midnight, or rests it 30 days on a second Undo within 14 days (SPEC BR-10, BR-17).
final class UndoUsualAdd implements UseCase<Unit, Entry> {
  /// Writes the quiet state to [_states], deletes from [_ledger] and reads "today" from [_clock].
  const UndoUsualAdd({required this._states, required this._ledger, required this._clock});

  final SuggestionStateRepository _states;
  final LedgerRepository _ledger;
  final Clock _clock;

  /// Returns [Right] with [unit] once [entry] is deleted, or [Left] with `DatabaseFailure` or
  /// `InvalidDataFailure` when the state can't be read or stored (nothing is deleted), or
  /// `EntryNotFoundFailure` when [entry] is already gone (its category is quiet all the same).
  @override
  TaskEither<Failure, Unit> call(Entry entry) => _states
      .of(entry.categoryId)
      // why: the quiet state is stored before the delete, because the delete notifies the
      // ledger's listeners and the reload they start must already see the category quiet.
      .flatMap(
        (Option<SuggestionState> previous) => _states.put(
          SuggestionGate.afterUndo(previous, categoryId: entry.categoryId, today: _clock.today()),
        ),
      )
      .flatMap((Unit _) => _ledger.delete(entry.id))
      .map((Entry _) => unit);
}
