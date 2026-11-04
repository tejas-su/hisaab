import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/entry_kind.dart';
import '../entities/recurring_rule.dart';
import '../repository/recurring_repository.dart';

/// Lists the active rules of one kind for Settings, soonest first: *Spent* for the fixed bills,
/// *Saved* for the savings (SPEC FR-SE-1, D120).
final class GetBills implements UseCase<List<RecurringRule>, EntryKind> {
  const GetBills({required this._recurring});

  final RecurringRepository _recurring;

  /// Returns [Right] with the bills (possibly empty; same-day bills in saved order), or [Left]
  /// with `DatabaseFailure`.
  @override
  TaskEither<Failure, List<RecurringRule>> call(EntryKind params) => _recurring.activeRules().map(
        (List<RecurringRule> rules) => rules.where((RecurringRule rule) => rule.kind == params).toList()
          ..sort((RecurringRule a, RecurringRule b) => a.nextDue.compareTo(b.nextDue)),
      );
}
