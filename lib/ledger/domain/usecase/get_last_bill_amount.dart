import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/time/clock.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/entry.dart';
import '../entities/recurring_rule.dart';
import '../repository/ledger_repository.dart';

/// Finds the amount last entered for a changing or card bill, so its keypad can say "Last
/// time ₹1,200", or "You said about ₹1,200" before the first time (D123).
final class GetLastBillAmount implements UseCase<Option<Money>, RecurringRule> {
  const GetLastBillAmount({required this._ledger, required this._clock});

  final LedgerRepository _ledger;
  final Clock _clock;

  /// How far back to look; a bill not entered for a year reads as never entered.
  static const int lookbackDays = 366;

  /// Returns [Right] with the latest entry's amount within [lookbackDays], [None] when the bill
  /// wasn't entered in that time, or [Left] with `DatabaseFailure`.
  // why: not from the schedule's anchor, which moves when the bill's day is changed and would
  // then miss the entries before it.
  @override
  TaskEither<Failure, Option<Money>> call(RecurringRule params) =>
      _ledger.entriesBetween(_clock.today().addDays(-lookbackDays), _clock.today()).map(
            (List<Entry> entries) => Option<Entry>.fromNullable(
              entries
                  .where((Entry e) => e.recurringId == params.id)
                  .fold<Entry?>(null, (Entry? latest, Entry e) => latest == null || e.date.isAfter(latest.date) ? e : latest),
            ).map((Entry e) => e.amount),
          );
}
