import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/amount_mode.dart';
import '../entities/entry.dart';
import '../entities/entry_draft.dart';
import '../entities/recurring_rule.dart';
import '../entry_validator.dart';
import '../repository/ledger_repository.dart';
import '../repository/recurring_repository.dart';

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
///
/// Editing the latest entry of a changing or card bill also makes its new amount that bill's
/// estimate, as entering it did (D123).
final class SaveEntry implements UseCase<Entry, SaveEntryParams> {
  const SaveEntry({required this._ledger, required this._recurring, required this._clock});

  final LedgerRepository _ledger;
  final RecurringRepository _recurring;
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
          (int id) => _ledger.replace(id, draft).flatMap((Entry entry) => _keepEstimate(entry).map((Unit _) => entry)),
        ),
      );

  // why: the entry is what counts; a failed estimate only means next month's prefill is older,
  // so it must not report the saved edit as failed.
  TaskEither<Failure, Unit> _keepEstimate(Entry entry) {
    final int? ruleId = entry.recurringId;
    if (ruleId == null) {
      return TaskEither<Failure, Unit>.right(unit);
    }
    return _recurring
        .activeRules()
        .flatMap((List<RecurringRule> rules) => _estimateFrom(entry, rules.where((RecurringRule r) => r.id == ruleId).firstOrNull))
        .orElse((Failure _) => TaskEither<Failure, Unit>.right(unit));
  }

  TaskEither<Failure, Unit> _estimateFrom(Entry entry, RecurringRule? rule) {
    if (rule == null || rule.amountMode == AmountMode.fixed || rule.amount == entry.amount) {
      return TaskEither<Failure, Unit>.right(unit);
    }
    return _ledger.entriesBetween(entry.date.addDays(1), _clock.today()).flatMap(
          (List<Entry> later) => later.any((Entry e) => e.recurringId == rule.id)
              ? TaskEither<Failure, Unit>.right(unit)
              : _recurring.update(rule.copyWith(amount: entry.amount)).map((RecurringRule _) => unit),
        );
  }
}
