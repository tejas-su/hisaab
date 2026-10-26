import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/entry.dart';
import '../entities/entry_draft.dart';
import '../entry_validator.dart';
import '../repository/ledger_repository.dart';

/// What to save: a [draft], either as a new entry or [replacing] an existing one (FR-AD-8).
final class SaveEntryParams extends Equatable {
  const SaveEntryParams(this.draft, {this.replacing = const Option<int>.none()});

  final EntryDraft draft;

  /// The id of the entry being edited; [None] adds a new entry.
  final Option<int> replacing;

  @override
  List<Object?> get props => <Object?>[draft, replacing];
}

/// Validates an entry against SPEC BR-10 for today and saves it.
final class SaveEntry implements UseCase<Entry, SaveEntryParams> {
  const SaveEntry({required this._ledger, required this._clock});

  final LedgerRepository _ledger;
  final Clock _clock;

  /// Returns [Right] with the saved entry, or [Left] with a validation failure
  /// (`InvalidAmountFailure`, `FutureDateFailure`, `NoteTooLongFailure`), `EntryNotFoundFailure`
  /// when the edited entry is gone, or `DatabaseFailure`.
  @override
  TaskEither<Failure, Entry> call(SaveEntryParams params) =>
      TaskEither<Failure, EntryDraft>.fromEither(EntryValidator.validate(params.draft, today: _clock.today()))
          .flatMap(
        (EntryDraft draft) => params.replacing.match(
          () => _ledger.add(draft),
          (int id) => _ledger.replace(id, draft),
        ),
      );
}
