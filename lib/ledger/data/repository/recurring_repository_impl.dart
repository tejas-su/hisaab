import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_row.dart';
import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../domain/entities/entry_draft.dart';
import '../../domain/entities/ledger_setup.dart';
import '../../domain/entities/occurrence.dart';
import '../../domain/entities/recurring_posting.dart';
import '../../domain/entities/recurring_rule.dart';
import '../../domain/entry_validator.dart';
import '../../domain/repository/recurring_repository.dart';
import '../datasource/recurring_local_data_source.dart';
import '../mapper/entry_mapper.dart';
import '../mapper/recurring_mapper.dart';
import '../model/entry_model.dart';
import '../model/recurring_model.dart';

/// [RecurringRepository] over sqflite.
final class RecurringRepositoryImpl implements RecurringRepository {
  const RecurringRepositoryImpl({required this._recurring, required this._clock});

  final RecurringLocalDataSource _recurring;
  final Clock _clock;

  @override
  TaskEither<Failure, List<RecurringRule>> activeRules() => dbTask(_recurring.activeRules)
      .chainEither((List<RecurringModel> models) => models.traverseEither(RecurringMapper.toEntity));

  /// Returns [Left] with a validation failure, before touching the database, if any occurrence
  /// breaks SPEC BR-10; `OR IGNORE` would otherwise drop it silently.
  @override
  TaskEither<Failure, int> post(RecurringPosting posting) => TaskEither<Failure, List<EntryModel>>.fromEither(
        posting.occurrences.traverseEither(_validatedModel),
      ).flatMap(
        (List<EntryModel> entries) => dbTask(
          () => _recurring.post(
            entries,
            posting.nextDueByRuleId.map((int id, CalendarDate date) => MapEntry<int, String>(id, date.toIso())),
          ),
        ),
      );

  @override
  TaskEither<Failure, Unit> startFresh(LedgerSetup setup) => dbTask(() async {
        await _recurring.startFresh(
          setup.rules.map(RecurringMapper.toModel).toList(),
          setup.entries.map((EntryDraft draft) => EntryMapper.toModel(draft, createdAt: _clock.now())).toList(),
        );
        return unit;
      });

  Either<Failure, EntryModel> _validatedModel(Occurrence occurrence) {
    final RecurringRule rule = occurrence.rule;
    final EntryDraft draft =
        EntryDraft(amount: rule.amount, kind: rule.kind, categoryId: rule.categoryId, date: occurrence.date);
    return EntryValidator.validate(draft, today: occurrence.date).map(
      (EntryDraft valid) => EntryMapper.toModel(valid, createdAt: _clock.now(), recurringId: rule.id),
    );
  }
}
