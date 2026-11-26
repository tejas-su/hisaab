import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/usecase/start_saving_for.dart';

import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

const PayCycle _nov = PayCycle(start: CalendarDate(2026, 11, 4), end: CalendarDate(2026, 12, 3));
const PayCycle _endOfMonth = PayCycle(start: CalendarDate(2026, 10, 31), end: CalendarDate(2026, 11, 29));

void main() {
  late FakeRecurringRepository recurring;
  late FakeCategoryRepository categories;
  late FakeClock clock;
  late StartSavingFor start;

  setUp(() {
    recurring = FakeRecurringRepository(<RecurringRule>[WorkedExample.salary]);
    categories = FakeCategoryRepository();
    clock = FakeClock(WorkedExample.now);
    start = StartSavingFor(
      addBill: AddBill(recurring: recurring, categories: categories, clock: clock),
      editBill: EditBill(recurring: recurring, categories: categories, clock: clock),
      recurring: recurring,
    );
  });

  StartSavingParams params({PayCycle cycle = _nov, Option<RecurringRule> existing = const Option<RecurringRule>.none()}) =>
      StartSavingParams(
        name: 'Mac',
        monthly: Money.fromMajor(5000),
        target: Money.fromMajor(67000),
        nextCycle: cycle,
        existing: existing,
      );

  Future<RecurringRule> started(StartSavingParams p) async =>
      (await start(p).run()).getOrElse((Failure f) => fail('unexpected $f'));

  test('a new saving is named, put in the day after payday, and given its target', () async {
    final RecurringRule rule = await started(params());

    expect(rule.label, 'Mac');
    expect(rule.kind, EntryKind.saved);
    expect(rule.amount, Money.fromMajor(5000));
    expect(rule.schedule.anchor.day, 5);
    expect(rule.target, Option<Money>.of(Money.fromMajor(67000)));
    expect(recurring.rules.firstWhere((RecurringRule r) => r.id == rule.id).target, rule.target);
  });

  test('a next cycle starting on the 31st puts in on the 1st', () async {
    final RecurringRule rule = await started(params(cycle: _endOfMonth));

    expect(rule.schedule.anchor.day, 1);
  });

  test('an existing saving keeps its id and day; amount and target change', () async {
    final RecurringRule first = await started(params());
    final RecurringRule again = await started(
      StartSavingParams(
        name: 'Mac',
        monthly: Money.fromMajor(8000),
        target: Money.fromMajor(90000),
        nextCycle: _endOfMonth,
        existing: Option<RecurringRule>.of(first),
      ),
    );

    expect(again.id, first.id);
    expect(again.schedule.anchor.day, 5);
    expect(again.amount, Money.fromMajor(8000));
    expect(again.target, Option<Money>.of(Money.fromMajor(90000)));
    expect(recurring.rules.where((RecurringRule r) => r.id == first.id).single, again);
  });

  test('a failure from AddBill is returned as Left', () async {
    recurring.failure = DatabaseFailure('boom');

    final Either<Failure, RecurringRule> result = await start(params()).run();

    expect(result.isLeft(), isTrue);
  });

  test('a failure from the target update is returned as Left', () async {
    final RecurringRule first = await started(params());
    recurring.failure = DatabaseFailure('boom');

    final Either<Failure, RecurringRule> result =
        await start(params(existing: Option<RecurringRule>.of(first))).run();

    expect(result.isLeft(), isTrue);
  });

  test('params compare by value', () {
    expect(params(), params());
  });
}
