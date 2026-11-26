import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/usecases/use_case.dart';
import '../entities/cycle_summary.dart';
import '../entities/recurring_rule.dart';
import '../entities/saving_totals.dart';
import '../repository/ledger_repository.dart';
import '../target_day_effect.dart';
import 'get_cycle_summary.dart';

/// Reads what the *Saving up to* question needs to say how a typed target moves today's share
/// (SPEC BR-23, AC-T3). Read once when the question opens; each digit is then a pure recompute.
final class GetTargetDayEffect
    implements UseCase<TargetDayEffect, RecurringRule> {
  const GetTargetDayEffect({required this._summary, required this._ledger});

  final GetCycleSummary _summary;
  final LedgerRepository _ledger;

  /// Returns [Right] with the effect for the saving [params], or [Left] with `DatabaseFailure` or
  /// `InvalidDataFailure` when today's summary or the saving totals can't be read.
  @override
  TaskEither<Failure, TargetDayEffect> call(RecurringRule params) =>
      _summary(const NoParams()).flatMap(
        (CycleSummary summary) => _ledger.savingTotals().map(
          (SavingTotals totals) =>
              TargetDayEffect(summary: summary, saving: params, totals: totals),
        ),
      );
}
