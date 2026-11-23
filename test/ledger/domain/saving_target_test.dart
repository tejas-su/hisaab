import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/ledger.dart';

RecurringRule _saving(int rupees, CalendarDate nextDue, {int paise = 0}) => RecurringRule(
      id: 1,
      label: 'RD',
      amount: Money(rupees * 100 + paise),
      kind: EntryKind.saved,
      categoryId: 1,
      schedule: Schedule(frequency: Frequency.monthly, anchor: nextDue),
      nextDue: nextDue,
    );

TargetProgress _progress(RecurringRule rule, int setAside, int target) => SavingTarget.progress(
      target: Money.fromMajor(target),
      setAside: Money.fromMajor(setAside),
      saving: rule,
    );

void main() {
  group('SavingTarget.progress (BR-23)', () {
    final RecurringRule rd = _saving(5000, const CalendarDate(2026, 11, 10));

    test('example B: 5,000 a month gives 10 May 2027', () {
      expect(_progress(rd, 18000, 50000), const TargetEstimate(CalendarDate(2027, 5, 10)));
    });

    test('example B: 4,000 a month gives 10 Jun 2027', () {
      final RecurringRule rule = _saving(4000, const CalendarDate(2026, 11, 10));
      expect(_progress(rule, 18000, 50000), const TargetEstimate(CalendarDate(2027, 6, 10)));
    });

    final RecurringRule monthly = _saving(1000, const CalendarDate(2026, 11, 5));

    test('example A: set aside equal to target is reached', () {
      expect(_progress(monthly, 12000, 12000), const TargetReached());
    });

    test('set aside above target is reached', () {
      expect(_progress(monthly, 13000, 12000), const TargetReached());
    });

    test('example A: 7,000 set aside gives 5 Mar 2027', () {
      expect(_progress(monthly, 7000, 12000), const TargetEstimate(CalendarDate(2027, 3, 5)));
    });

    test('example A: nothing set aside gives 5 Oct 2027', () {
      expect(_progress(monthly, 0, 12000), const TargetEstimate(CalendarDate(2027, 10, 5)));
    });

    test('one paisa short needs one put-in, on nextDue', () {
      expect(
        SavingTarget.progress(target: const Money(100001), setAside: Money.fromMajor(1000), saving: monthly),
        const TargetEstimate(CalendarDate(2026, 11, 5)),
      );
    });

    test('a 31st saving clamps to 28 Feb 2027', () {
      final RecurringRule rule = _saving(1000, const CalendarDate(2027, 1, 31));
      expect(_progress(rule, 0, 2000), const TargetEstimate(CalendarDate(2027, 2, 28)));
    });

    test('a 31st saving clamps to 29 Feb in a leap year', () {
      final RecurringRule rule = _saving(1000, const CalendarDate(2028, 1, 31));
      expect(_progress(rule, 0, 2000), const TargetEstimate(CalendarDate(2028, 2, 29)));
    });

    test('crosses the year', () {
      final RecurringRule rule = _saving(1000, const CalendarDate(2026, 12, 10));
      expect(_progress(rule, 0, 2000), const TargetEstimate(CalendarDate(2027, 1, 10)));
    });

    test('exactly 120 put-ins is still an estimate', () {
      expect(_progress(monthly, 0, 120000), const TargetEstimate(CalendarDate(2036, 10, 5)));
    });

    test('121 put-ins is far', () {
      expect(_progress(monthly, 0, 120001), const TargetFar());
    });

    test('Rs 1 towards 50,000 is far', () {
      expect(_progress(_saving(1, const CalendarDate(2026, 11, 5)), 0, 50000), const TargetFar());
    });
  });
}
