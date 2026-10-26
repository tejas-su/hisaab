import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/entry.dart';
import '../repository/ledger_repository.dart';

/// Undoes a delete by putting the entry back exactly as it was (SPEC BR-10).
final class RestoreEntry implements UseCase<Entry, Entry> {
  const RestoreEntry({required this._ledger});

  final LedgerRepository _ledger;

  /// Returns [Right] with the restored entry, or [Left] with `EntryNotFoundFailure` or
  /// `DatabaseFailure`.
  @override
  TaskEither<Failure, Entry> call(Entry entry) => _ledger.restore(entry);
}
