import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/entry.dart';
import '../repository/ledger_repository.dart';

/// Deletes an entry by id at once; the caller offers Undo with the returned entry (SPEC BR-10).
final class DeleteEntry implements UseCase<Entry, int> {
  const DeleteEntry({required this._ledger});

  final LedgerRepository _ledger;

  /// Returns [Right] with the deleted entry, or [Left] with `EntryNotFoundFailure` or
  /// `DatabaseFailure`.
  @override
  TaskEither<Failure, Entry> call(int id) => _ledger.delete(id);
}
