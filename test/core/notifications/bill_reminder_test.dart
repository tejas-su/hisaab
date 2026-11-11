import 'package:hisaab/core/notifications/bill_reminder.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  const CalendarDate nov18 = CalendarDate(2026, 11, 18);
  final BillReminder reminder = BillReminder(ruleId: 3, date: nov18, billName: 'Electricity', isCard: false, at: DateTime(2026, 11, 18, 9));

  group('BillReminder', () {
    test('the same occurrence always gets the same id', () {
      expect(reminder.id, BillReminder.idFor(3, nov18));
      expect(BillReminder.idFor(3, nov18), 3 * 100000 + const CalendarDate(2020, 1, 1).daysUntil(nov18));
    });

    test('another day or another bill gets another id', () {
      expect(BillReminder.idFor(3, nov18.addDays(1)), isNot(reminder.id));
      expect(BillReminder.idFor(4, nov18), isNot(reminder.id));
    });

    test('the largest rule id still fits a 32-bit id', () {
      expect(BillReminder.idFor(21474, const CalendarDate(2099, 12, 31)), lessThan(0x7FFFFFFF));
    });

    test('its tap names the bill and the day', () {
      expect(reminder.tap, const BillReminderTap(ruleId: 3, date: nov18));
    });

    test('compares by its fields', () {
      expect(reminder, BillReminder(ruleId: 3, date: nov18, billName: 'Electricity', isCard: false, at: DateTime(2026, 11, 18, 9)));
    });
  });

  group('BillReminderTap', () {
    test('carries the bill link', () {
      expect(const BillReminderTap(ruleId: 3, date: nov18).link, 'hisaab://bill/3/2026-11-18');
    });

    test('reads its own link back', () {
      expect(BillReminderTap.parse('hisaab://bill/3/2026-11-18'), const Option<BillReminderTap>.of(BillReminderTap(ruleId: 3, date: nov18)));
    });

    const List<String?> notBillLinks = <String?>[
      null,
      '',
      'https://bill/3/2026-11-18',
      'hisaab://entry/3/2026-11-18',
      'hisaab://bill/3',
      'hisaab://bill/x/2026-11-18',
      'hisaab://bill/3/2026-02-30',
      'hisaab://bill/3/2026-11-18/more',
    ];
    for (final String? link in notBillLinks) {
      test('reads "$link" as no bill', () {
        expect(BillReminderTap.parse(link), const Option<BillReminderTap>.none());
      });
    }
  });
}
