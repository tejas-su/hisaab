import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_row.dart';
import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../domain/entities/bill_skip.dart';
import '../../domain/entities/entry_draft.dart';
import '../../domain/entities/entry_kind.dart';
import '../../domain/entities/ledger_setup.dart';
import '../../domain/entities/occurrence.dart';
import '../../domain/entities/recurring_draft.dart';
import '../../domain/entities/recurring_posting.dart';
import '../../domain/entities/recurring_rule.dart';
import '../../domain/entry_validator.dart';
import '../../domain/failures/ledger_failures.dart';
import '../../domain/repository/recurring_repository.dart';
import '../datasource/recurring_local_data_source.dart';
import '../mapper/entry_mapper.dart';
import '../mapper/recurring_mapper.dart';
import '../model/entry_model.dart';
import '../model/recurring_model.dart';

/// [RecurringRepository] over sqflite; owns the [changes] stream, closed by [dispose].
final class RecurringRepositoryImpl implements RecurringRepository {
  RecurringRepositoryImpl({required this._recurring, required this._clock});

  final RecurringLocalDataSource _recurring;
  final Clock _clock;
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

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

  @override
  TaskEither<Failure, RecurringRule> add(RecurringDraft draft) => dbTask(() => _recurring.insert(RecurringMapper.toModel(draft)))
      .map((int id) => _notify(_ruleFrom(id, draft)));

  @override
  TaskEither<Failure, RecurringRule> update(RecurringRule rule) =>
      dbTask(() => _recurring.update(RecurringMapper.toModel(rule.draft, id: rule.id)))
          .flatMap((int changed) => _changedOne(changed, rule.id))
          .map((Unit _) => _notify(rule));

  @override
  TaskEither<Failure, Unit> setActive(int id, {required bool active}) =>
      dbTask(() => _recurring.setActive(id, active: active)).flatMap((int changed) => _changedOne(changed, id)).map(_notify);

  @override
  TaskEither<Failure, Unit> skip(BillSkip skip) =>
      dbTask(() => _recurring.skip(skip.ruleId, skip.date.toIso())).map((void _) => _notify(unit));

  @override
  TaskEither<Failure, Unit> unskip(BillSkip skip) =>
      dbTask(() => _recurring.unskip(skip.ruleId, skip.date.toIso())).map((void _) => _notify(unit));

  @override
  TaskEither<Failure, List<BillSkip>> skipsBetween(CalendarDate from, CalendarDate to) =>
      dbTask(() => _recurring.skipsBetween(from.toIso(), to.toIso())).chainEither(
        (List<({int ruleId, String date})> rows) => rows.traverseEither(
          (({int ruleId, String date}) row) =>
              CalendarDate.parse(row.date).map((CalendarDate date) => BillSkip(ruleId: row.ruleId, date: date)),
        ),
      );

  /// Closes [changes]; called when the app's services are torn down.
  Future<void> dispose() => _changes.close();

  T _notify<T>(T value) {
    _changes.add(null);
    return value;
  }

  static TaskEither<Failure, Unit> _changedOne(int changed, int id) => changed == 1
      ? TaskEither<Failure, Unit>.right(unit)
      : TaskEither<Failure, Unit>.left(RuleNotFoundFailure('No active rule $id'));

  static RecurringRule _ruleFrom(int id, RecurringDraft draft) => RecurringRule(
        id: id,
        label: draft.label,
        amount: draft.amount,
        kind: draft.kind,
        categoryId: draft.categoryId,
        schedule: draft.schedule,
        nextDue: draft.nextDue,
        isIncomeSource: draft.isIncomeSource,
        icon: draft.icon,
        amountMode: draft.amountMode,
      );

  Either<Failure, EntryModel> _validatedModel(Occurrence occurrence) {
    final RecurringRule rule = occurrence.rule;
    // why: a saving's entry carries its rule's name, so the Today row can say "RD" (D120).
    final EntryDraft draft = EntryDraft(
      amount: rule.amount,
      kind: rule.kind,
      categoryId: rule.categoryId,
      date: occurrence.date,
      note: rule.kind == EntryKind.saved ? rule.label : null,
    );
    return EntryValidator.validate(draft, today: occurrence.date).map(
      (EntryDraft valid) => EntryMapper.toModel(valid, createdAt: _clock.now(), recurringId: rule.id),
    );
  }
}
