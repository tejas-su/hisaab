import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/ledger/ledger.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

/// BR-23, owner 2026-11-26: a typed target moves today's share only through the capped
/// reservation of a put-in still due this cycle. Worked example: today 26 Oct 2026, cycle 4 Oct to
/// 3 Nov (9 days left); a ₹5,000 saving is due on 30 Oct with ₹47,000 set aside.
void main() {
  RecurringRule saving({int? target}) => RecurringRule(
        id: 5,
        label: 'Insurance',
        amount: Money.fromMajor(5000),
        kind: EntryKind.saved,
        categoryId: SeedCategoryIds.saved,
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 9, 30)),
        nextDue: const CalendarDate(2026, 10, 30),
        target: target == null ? const Option<Money>.none() : Option<Money>.of(Money.fromMajor(target)),
      );

  final Entry putIn = Entry(
    id: 800,
    amount: Money.fromMajor(47000),
    kind: EntryKind.saved,
    categoryId: SeedCategoryIds.saved,
    date: const CalendarDate(2026, 9, 30),
    createdAt: DateTime(2026, 9, 30, 12),
    recurringId: 5,
  );

  ({GetCycleSummary summary, GetTargetDayEffect effect, FakeLedgerRepository ledger}) build(RecurringRule rule) {
    final FakeLedgerRepository ledger = FakeLedgerRepository(<Entry>[...WorkedExample.entries, putIn]);
    addTearDown(ledger.dispose);
    final GetCycleSummary summary = GetCycleSummary(
      ledger: ledger,
      recurring: FakeRecurringRepository(<RecurringRule>[...WorkedExample.rules, rule]),
      settings: FakeBudgetSettingsRepository(),
      periods: const PeriodCalculator(),
      clock: FakeClock(WorkedExample.now),
    );
    return (summary: summary, effect: GetTargetDayEffect(summary: summary, ledger: ledger), ledger: ledger);
  }

  Future<Money> shareWith(RecurringRule rule) async =>
      (await build(rule).summary(const NoParams()).run()).getOrElse((Failure f) => fail(f.message)).todayShare;

  Future<Money> changeFor(RecurringRule rule, int typed) async {
    final TargetDayEffect effect = (await build(rule).effect(rule).run()).getOrElse((Failure f) => fail(f.message));
    return effect.changeFor(Money.fromMajor(typed));
  }

  test('a target that cuts the last put-in short raises today\'s share by what Home will show', () async {
    final Money change = await changeFor(saving(), 48000);

    expect(change > Money.zero, isTrue);
    expect(change, await shareWith(saving(target: 48000)) - await shareWith(saving()));
  });

  test('raising a target so a cut put-in is due in full lowers today\'s share', () async {
    final Money change = await changeFor(saving(target: 48000), 60000);

    expect(change.isNegative, isTrue);
    expect(change, await shareWith(saving(target: 60000)) - await shareWith(saving(target: 48000)));
  });

  test('a target already covered reserves nothing, so the whole put-in comes back', () async {
    expect(await changeFor(saving(), 40000), await shareWith(saving(target: 40000)) - await shareWith(saving()));
    expect(await changeFor(saving(), 40000) > Money.zero, isTrue);
  });

  test('a target beyond this cycle\'s put-ins changes nothing', () async {
    expect(await changeFor(saving(), 100000), Money.zero);
  });

  test('the saving\'s own target changes nothing', () async {
    expect(await changeFor(saving(target: 48000), 48000), Money.zero);
  });

  test('two reads of the same book are equal, so the sheet state does not churn', () async {
    final RecurringRule rule = saving();
    final ({GetCycleSummary summary, GetTargetDayEffect effect, FakeLedgerRepository ledger}) built = build(rule);

    expect(await built.effect(rule).run(), await built.effect(rule).run());
  });

  test('returns the saving totals failure', () async {
    final RecurringRule rule = saving();
    final ({GetCycleSummary summary, GetTargetDayEffect effect, FakeLedgerRepository ledger}) built = build(rule);
    built.ledger.failure = const InvalidDataFailure('totals');

    expect((await built.effect(rule).run()).isLeft(), isTrue);
  });
}
