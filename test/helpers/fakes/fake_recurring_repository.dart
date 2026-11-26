import 'dart:async';

import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/domain/entities/bill_skip.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/entities/ledger_setup.dart';
import 'package:hisaab/ledger/domain/entities/recurring_draft.dart';
import 'package:hisaab/ledger/domain/entities/recurring_posting.dart';
import 'package:hisaab/ledger/domain/entities/recurring_rule.dart';
import 'package:hisaab/ledger/domain/failures/ledger_failures.dart';
import 'package:hisaab/ledger/domain/repository/recurring_repository.dart';
import 'package:fpdart/fpdart.dart';

import 'fake_ledger_repository.dart';

/// An in-memory [RecurringRepository] that records what was posted and set up. [rules] are the
/// active ones; a stopped rule moves to [stopped].
final class FakeRecurringRepository implements RecurringRepository {
  /// [ledger], when given, is where [removeWithPostedEntries] deletes the rule's entries, and
  /// its failure fails that call, as one database would.
  FakeRecurringRepository([this.rules = const <RecurringRule>[], this.ledger]);

  final FakeLedgerRepository? ledger;

  List<RecurringRule> rules;
  List<RecurringRule> stopped = <RecurringRule>[];
  final StreamController<void> _changes = StreamController<void>.broadcast(sync: true);
  int _nextId = 100;
  Failure? failure;

  /// Failure for [startFresh] only, to test partial onboarding.
  Failure? startFreshFailure;
  final List<RecurringPosting> postings = <RecurringPosting>[];
  final List<LedgerSetup> setups = <LedgerSetup>[];

  /// Every rule written by [update], in order.
  final List<RecurringRule> updates = <RecurringRule>[];

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
              amountMode: draft.amountMode,
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

  /// When set, the next [update] waits for this to complete before writing, so a test can
  /// send a second save while the first is in flight.
  Completer<void>? nextUpdateGate;

  @override
  TaskEither<Failure, RecurringRule> update(RecurringRule rule) {
    final Completer<void>? gate = nextUpdateGate;
    nextUpdateGate = null;
    return gate == null ? _update(rule) : TaskEither<Failure, Unit>(() async {
      await gate.future;
      return Either<Failure, Unit>.right(unit);
    }).flatMap((Unit _) => _update(rule));
  }

  TaskEither<Failure, RecurringRule> _update(RecurringRule rule) {
    if (failure == null && !rules.any((RecurringRule r) => r.id == rule.id)) {
      return TaskEither<Failure, RecurringRule>.left(RuleNotFoundFailure('No rule ${rule.id}'));
    }
    return _run(() {
      updates.add(rule);
      rules = <RecurringRule>[for (final RecurringRule r in rules) r.id == rule.id ? rule : r];
      _changes.add(null);
      return rule;
    });
  }

  /// Writes the reached marker over the stored rule [id], recorded in [updates] and gated by
  /// [nextUpdateGate] like [update].
  @override
  TaskEither<Failure, Unit> markTargetReached(int id, Money target, CalendarDate on) {
    final RecurringRule? stored = rules.where((RecurringRule r) => r.id == id).firstOrNull;
    if (failure == null && stored == null) {
      return TaskEither<Failure, Unit>.left(RuleNotFoundFailure('No rule $id'));
    }
    final RecurringRule? marked = stored?.copyWith(
      targetReachedFor: Option<Money>.of(target),
      targetReachedOn: Option<CalendarDate>.of(on),
    );
    return marked == null ? _run(() => unit) : update(marked).map((RecurringRule _) => unit);
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
  TaskEither<Failure, Unit> removeWithPostedEntries(int id, {required CalendarDate since}) {
    final Failure? current = failure ?? ledger?.failure;
    if (current != null) {
      return TaskEither<Failure, Unit>.left(current);
    }
    if (!rules.any((RecurringRule r) => r.id == id)) {
      return TaskEither<Failure, Unit>.left(RuleNotFoundFailure('No rule $id'));
    }
    ledger?.entries.removeWhere((Entry e) => e.recurringId == id && !e.date.isBefore(since));
    return setActive(id, active: false);
  }

  /// The skips recorded by [skip], in order; [unskip] removes one.
  List<BillSkip> skips = <BillSkip>[];

  @override
  TaskEither<Failure, Unit> skip(BillSkip skip) => _run(() {
        skips = <BillSkip>[...skips.where((BillSkip s) => s != skip), skip];
        _changes.add(null);
        return unit;
      });

  @override
  TaskEither<Failure, Unit> unskip(BillSkip skip) => _run(() {
        skips = <BillSkip>[...skips.where((BillSkip s) => s != skip)];
        _changes.add(null);
        return unit;
      });

  /// Failure for [skipsBetween] only.
  Failure? skipsFailure;

  @override
  TaskEither<Failure, List<BillSkip>> skipsBetween(CalendarDate from, CalendarDate to) =>
      _run(() => skips.where((BillSkip s) => !s.date.isBefore(from) && !s.date.isAfter(to)).toList(), skipsFailure);

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
        amountMode: draft.amountMode,
        target: draft.target,
        targetReachedFor: draft.targetReachedFor,
        targetReachedOn: draft.targetReachedOn,
      );
}
