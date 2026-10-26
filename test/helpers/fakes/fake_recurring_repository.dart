import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/ledger/domain/entities/ledger_setup.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_draft.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_posting.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/ledger/domain/repository/recurring_repository.dart';
import 'package:fpdart/fpdart.dart';

/// An in-memory [RecurringRepository] that records what was posted and set up.
final class FakeRecurringRepository implements RecurringRepository {
  FakeRecurringRepository([this.rules = const <RecurringRule>[]]);

  List<RecurringRule> rules;
  Failure? failure;

  /// Failure for [startFresh] only, to test partial onboarding.
  Failure? startFreshFailure;
  final List<RecurringPosting> postings = <RecurringPosting>[];
  final List<LedgerSetup> setups = <LedgerSetup>[];

  TaskEither<Failure, T> _run<T>(T Function() action, [Failure? override]) {
    final Failure? current = override ?? failure;
    return current == null ? TaskEither<Failure, T>.right(action()) : TaskEither<Failure, T>.left(current);
  }

  @override
  TaskEither<Failure, List<RecurringRule>> activeRules() => _run(() => rules);

  @override
  TaskEither<Failure, int> post(RecurringPosting posting) => _run(() {
        postings.add(posting);
        return posting.occurrences.length;
      });

  /// Records [setup] and replaces [rules] with it, ids from 1.
  @override
  TaskEither<Failure, Unit> startFresh(LedgerSetup setup) => _run(() {
        setups.add(setup);
        rules = <RecurringRule>[
          for (final (int index, RecurringDraft draft) in setup.rules.indexed)
            RecurringRule(
              id: index + 1,
              label: draft.label,
              amount: draft.amount,
              kind: draft.kind,
              categoryId: draft.categoryId,
              schedule: draft.schedule,
              nextDue: draft.nextDue,
              isIncomeSource: draft.isIncomeSource,
            ),
        ];
        return unit;
      }, startFreshFailure);
}
