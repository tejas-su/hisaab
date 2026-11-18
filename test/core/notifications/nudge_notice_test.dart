import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/notifications/nudge_notice.dart';

void main() {
  group('NudgeNotice', () {
    test('is after now only when it is still ahead', () {
      final DateTime now = DateTime(2026, 11, 18, 20);
      NudgeNotice at(DateTime when) => NudgeNotice(id: 1, at: when, categoryName: const Option<String>.none());
      expect(at(now.add(const Duration(minutes: 1))).isAfter(now), isTrue);
      expect(at(now).isAfter(now), isFalse);
      expect(at(now.subtract(const Duration(minutes: 1))).isAfter(now), isFalse);
    });

    test('compares by its fields', () {
      final DateTime at = DateTime(2026, 11, 18, 20);
      expect(NudgeNotice(id: 1, at: at, categoryName: const Option<String>.of('Food')), NudgeNotice(id: 1, at: at, categoryName: const Option<String>.of('Food')));
      expect(NudgeNotice(id: 1, at: at, categoryName: const Option<String>.none()), isNot(NudgeNotice(id: 2, at: at, categoryName: const Option<String>.none())));
      expect(NudgeNotice(id: 1, at: at, categoryName: const Option<String>.none()), isNot(NudgeNotice(id: 1, at: at, categoryName: const Option<String>.of('Food'))));
    });
  });
}
