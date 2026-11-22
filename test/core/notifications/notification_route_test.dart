import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/notifications/bill_reminder.dart';
import 'package:hisaab/core/notifications/notification_route.dart';
import 'package:hisaab/core/time/calendar_date.dart';

void main() {
  group('NotificationRoute.of', () {
    test('a bill link goes to the bill reminders', () {
      expect(NotificationRoute.of('hisaab://bill/3/2026-11-18'), NotificationRoute.bill);
    });

    test('the link a bill reminder carries routes to bills, so arming them never matches a nudge', () {
      const BillReminderTap tap = BillReminderTap(ruleId: 3, date: CalendarDate(2026, 11, 18));

      expect(NotificationRoute.of(tap.link), NotificationRoute.bill);
      expect(NotificationRoute.of(NotificationRoute.nudgeLink), isNot(NotificationRoute.bill));
    });

    test('the nudge link goes to the nudges', () {
      expect(NotificationRoute.of('hisaab://nudge'), NotificationRoute.nudge);
    });

    test('no payload, garbage and other links are ignored', () {
      expect(NotificationRoute.of(null), NotificationRoute.ignored);
      expect(NotificationRoute.of(''), NotificationRoute.ignored);
      expect(NotificationRoute.of('not a link'), NotificationRoute.ignored);
      expect(NotificationRoute.of('hisaab://add'), NotificationRoute.ignored);
      expect(NotificationRoute.of('https://nudge'), NotificationRoute.ignored);
    });
  });
}
