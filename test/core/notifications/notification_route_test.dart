import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/notifications/notification_route.dart';

void main() {
  group('NotificationRoute.of', () {
    test('a bill link goes to the bill reminders', () {
      expect(NotificationRoute.of('hisaab://bill/3/2026-11-18'), NotificationRoute.bill);
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
