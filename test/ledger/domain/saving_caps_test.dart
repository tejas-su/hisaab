import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/domain/due_amounts.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';
import 'package:hisaab/ledger/domain/entities/frequency.dart';
import 'package:hisaab/ledger/domain/entities/recurring_rule.dart';
import 'package:hisaab/ledger/domain/entities/schedule.dart';
import 'package:hisaab/ledger/domain/saving_caps.dart';

/// BR-23, D213: the capped walk over a saving's put-ins.
void main() {
  RecurringRule saving({int? target}) => RecurringRule(
        id: 1,
        label: 'Trip',
        amount: Money.fromMajor(1000),
        kind: EntryKind.saved,
        categoryId: 1,
        schedule: const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 1)),
        nextDue: const CalendarDate(2026, 10, 1),
        target: target == null ? const Option<Money>.none() : Option<Money>.of(Money.fromMajor(target)),
      );

  List<DatedAmount> due(int count) => <DatedAmount>[
        for (int i = 0; i < count; i++) (date: CalendarDate(2026, 10, 1).addDays(7 * i), amount: Money.fromMajor(1000)),
      ];

  test('no target keeps every put-in', () {
    expect(SavingCaps.capped(saving(), due(3), Money.zero), due(3));
  });

  test('a reached target keeps nothing', () {
    expect(SavingCaps.capped(saving(target: 5000), due(3), Money.fromMajor(5000)), isEmpty);
    expect(SavingCaps.capped(saving(target: 5000), due(3), Money.fromMajor(9000)), isEmpty);
  });

  test('the last put-in is short and later ones are dropped, in date order', () {
    final List<DatedAmount> capped = SavingCaps.capped(saving(target: 5000), due(4), Money.fromMajor(3500));

    expect(capped.map((DatedAmount d) => d.amount), <Money>[Money.fromMajor(1000), Money.fromMajor(500)]);
    expect(capped.map((DatedAmount d) => d.date), <CalendarDate>[const CalendarDate(2026, 10, 1), const CalendarDate(2026, 10, 8)]);
  });

  test('a gap larger than all put-ins keeps them all', () {
    expect(SavingCaps.capped(saving(target: 50000), due(2), Money.zero), due(2));
  });
}
