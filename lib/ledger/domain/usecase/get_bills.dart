import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/entry_kind.dart';
import '../entities/recurring_rule.dart';
import '../repository/recurring_repository.dart';

/// Lists the fixed bills for Settings: active *Spent* rules, soonest first (SPEC FR-SE-1).
final class GetBills implements UseCase<List<RecurringRule>, NoParams> {
  const GetBills({required this._recurring});

  final RecurringRepository _recurring;

  /// Returns [Right] with the bills (possibly empty; same-day bills in saved order), or [Left]
  /// with `DatabaseFailure`.
  @override
  TaskEither<Failure, List<RecurringRule>> call(NoParams params) => _recurring.activeRules().map(
        (List<RecurringRule> rules) => rules.where((RecurringRule rule) => rule.kind == EntryKind.spent).toList()
          ..sort((RecurringRule a, RecurringRule b) => a.nextDue.compareTo(b.nextDue)),
      );
}
