import 'dart:async';

import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/ledger/domain/entities/ledger_setup.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_draft.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_posting.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/ledger/domain/failures/ledger_failures.dart';
import 'package:expense_tracker/ledger/domain/repository/recurring_repository.dart';
import 'package:fpdart/fpdart.dart';

/// An in-memory [RecurringRepository] that records what was posted and set up. [rules] are the
/// active ones; a stopped rule moves to [stopped].
final class FakeRecurringRepository implements RecurringRepository {
  FakeRecurringRepository([this.rules = const <RecurringRule>[]]);

  List<RecurringRule> rules;
  List<RecurringRule> stopped = <RecurringRule>[];
  final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);
  int _nextId = 100;
  Failure? failure;

  /// Failure for [startFresh] only, to test partial onboarding.
  Failure? startFreshFailure;
  final List<RecurringPosting> postings = <RecurringPosting>[];
  final List<LedgerSetup> setups = <LedgerSetup>[];

  TaskEither<Failure, T> _run<T>(T Function() action, [Failure? override]) {
    final Failure? current = override ?? failure;
    return current == null ? TaskEither<Failure, T>.right(action()) : TaskEither<Failure, T>.left(current);
  }

  /// When set, the next [activeRules] read takes the rules as they are now but answers only
  /// once this completes, so a test can finish a later read first.
  Completer<void>? nextReadGate;

  @override
  TaskEither<Failure, List<RecurringRule>> activeRules() {
    final Completer<void>? gate = nextReadGate;
    nextReadGate = null;
    final TaskEither<Failure, List<RecurringRule>> read = _run(() => rules);
    return gate == null ? read : TaskEither<Failure, Unit>(() async {
      await gate.future;
      return Either<Failure, Unit>.right(unit);
    }).flatMap((Unit _) => read);
  }

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
              icon: draft.icon,
            ),
        ];
        return unit;
      }, startFreshFailure);

  @override
  TaskEither<Failure, RecurringRule> add(RecurringDraft draft) => _run(() {
        final RecurringRule rule = _ruleFrom(_nextId++, draft);
        rules = <RecurringRule>[...rules, rule];
        _changes.add(null);
        return rule;
      });

  @override
  TaskEither<Failure, RecurringRule> update(RecurringRule rule) {
    if (failure == null && !rules.any((RecurringRule r) => r.id == rule.id)) {
      return TaskEither<Failure, RecurringRule>.left(RuleNotFoundFailure('No rule ${rule.id}'));
    }
    return _run(() {
      rules = <RecurringRule>[for (final RecurringRule r in rules) r.id == rule.id ? rule : r];
      _changes.add(null);
      return rule;
    });
  }

  @override
  TaskEither<Failure, Unit> setActive(int id, {required bool active}) {
    final List<RecurringRule> from = active ? stopped : rules;
    final RecurringRule? rule = from.where((RecurringRule r) => r.id == id).firstOrNull;
    if (failure == null && rule == null) {
      return TaskEither<Failure, Unit>.left(RuleNotFoundFailure('No rule $id'));
    }
    return _run(() {
      final List<RecurringRule> rest = <RecurringRule>[...from.where((RecurringRule r) => r.id != id)];
      final List<RecurringRule> to = <RecurringRule>[...active ? rules : stopped, ?rule];
      rules = active ? to : rest;
      stopped = active ? rest : to;
      _changes.add(null);
      return unit;
    });
  }

  @override
  Stream<void> get changes => _changes.stream;

  /// Closes the change stream.
  Future<void> dispose() => _changes.close();

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
      );
}
