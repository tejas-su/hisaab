import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_recurring_repository.dart';

void main() {
  final RecurringRule electricity = RecurringRule(
    id: 8,
    label: 'Electricity',
    amount: Money.fromMajor(1200),
    kind: EntryKind.spent,
    categoryId: 5,
    schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 20)),
    nextDue: const CalendarDate(2026, 10, 20),
    amountMode: AmountMode.varies,
  );
  const BillSkip skip = BillSkip(ruleId: 8, date: CalendarDate(2026, 10, 20));

  test('Didn\'t go out this month records a skip and returns it (D123)', () async {
    final FakeRecurringRepository recurring = FakeRecurringRepository(<RecurringRule>[electricity]);
    expect(
      await SkipBillOccurrence(recurring: recurring)(Occurrence(rule: electricity, date: const CalendarDate(2026, 10, 20))).run(),
      Either<Failure, BillSkip>.right(skip),
    );
    expect(recurring.skips, <BillSkip>[skip]);
  });

  test('Undo removes the skip', () async {
    final FakeRecurringRepository recurring = FakeRecurringRepository(<RecurringRule>[electricity])..skips = <BillSkip>[skip];
    expect(await UnskipBillOccurrence(recurring: recurring)(skip).run(), Either<Failure, Unit>.right(unit));
    expect(recurring.skips, isEmpty);
  });
}
