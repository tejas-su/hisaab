import 'dart:async';

import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/settings/presentation/bloc/income_bloc.dart';
import 'package:expense_tracker/settings/presentation/bloc/income_event.dart';
import 'package:expense_tracker/settings/presentation/bloc/income_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeRecurringRepository recurring;
  late FakeLedgerRepository ledger;
  late IncomeBloc bloc;

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    ledger = FakeLedgerRepository(WorkedExample.entries);
    final FakeClock clock = FakeClock(WorkedExample.now);
    bloc = IncomeBloc(
      getIncome: GetIncome(recurring: recurring, ledger: ledger, clock: clock),
      recurring: recurring,
      ledger: ledger,
    );
  });

  tearDown(() => bloc.close());

  group('IncomeBloc', () {
    test('starts loading', () {
      expect(bloc.state, const IncomeLoading());
    });

    test('loads the income', () async {
      await bloc.dispatch(const IncomeLoadRequested());
      expect(
        bloc.state,
        isA<IncomeReady>().having((IncomeReady r) => r.income.rule, 'rule', Option<RecurringRule>.of(WorkedExample.salary)),
      );
    });

    test('a failed load shows the failure', () async {
      recurring.failure = DatabaseFailure('boom');
      await bloc.dispatch(const IncomeLoadRequested());
      expect(bloc.state, isA<IncomeFailed>());
    });

    test('reloads when a rule changes', () async {
      await bloc.dispatch(const IncomeLoadRequested());
      await recurring.update(WorkedExample.salary.copyWith(amount: Money.fromMajor(50000))).run();
      await bloc.dispatch(const IncomeLoadRequested());
      expect((bloc.state as IncomeReady).income.rule.toNullable()?.amount, Money.fromMajor(50000));
    });

    test('a rule change triggers a reload by itself', () async {
      await bloc.dispatch(const IncomeLoadRequested());
      final Future<void> next = expectLater(
        bloc.stream,
        emits(isA<IncomeReady>().having((IncomeReady r) => r.income.rule.toNullable()?.amount, 'amount', Money.fromMajor(50000))),
      );
      await recurring.update(WorkedExample.salary.copyWith(amount: Money.fromMajor(50000))).run();
      await next;
    });

    test('an entry change triggers a reload by itself', () async {
      await bloc.dispatch(const IncomeLoadRequested());
      final Entry pay = ledger.entries.firstWhere((Entry e) => e.recurringId == WorkedExample.salary.id);
      final Future<void> next = expectLater(
        bloc.stream,
        emits(isA<IncomeReady>().having((IncomeReady r) => r.income.latestPay.toNullable()?.amount, 'pay', Money.fromMajor(50000))),
      );
      await CorrectLatestPay(ledger: ledger)(CorrectLatestPayParams(pay: pay, amount: Money.fromMajor(50000))).run();
      await next;
    });

    test('a slow older load never lands after a newer one (restartable)', () async {
      final Completer<void> gate = Completer<void>();
      ledger.nextReadGate = gate;
      bloc.add(const IncomeLoadRequested());
      await Future<void>.delayed(Duration.zero);
      recurring.rules = <RecurringRule>[WorkedExample.rent];
      await bloc.dispatch(const IncomeLoadRequested());
      gate.complete();
      await Future<void>.delayed(Duration.zero);
      expect((bloc.state as IncomeReady).income.rule, const Option<RecurringRule>.none());
    });
  });

  group('Income events and states', () {
    test('compare by their fields', () {
      expect(const IncomeLoadRequested(), const IncomeLoadRequested());
      expect(const IncomeLoading(), const IncomeLoading());
      // why: const instances are identical, so == never reads props; hashCode always does.
      expect(const IncomeLoadRequested().hashCode, const IncomeLoadRequested().hashCode);
      expect(const IncomeLoading().hashCode, const IncomeLoading().hashCode);
      expect(IncomeFailed(DatabaseFailure('a')), IncomeFailed(DatabaseFailure('a')));
      expect(const IncomeReady(Income(rule: Option<RecurringRule>.none())), const IncomeReady(Income(rule: Option<RecurringRule>.none())));
    });
  });
}
