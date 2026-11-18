import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/notifications/nudge_notice.dart';

import 'fake_nudges.dart';

void main() {
  group('FakeNudges', () {
    test('records what was armed and asked', () async {
      final FakeNudges nudges = FakeNudges(granted: false, launchedBy: true);
      final List<NudgeNotice> notices = <NudgeNotice>[NudgeNotice(id: 1, at: DateTime(2026, 11, 18, 20), categoryName: const Option<String>.none())];

      await nudges.arm(notices);

      expect(nudges.scheduled, notices);
      expect(nudges.arms, 1);
      expect(await nudges.requestPermission(), isFalse);
      expect(nudges.permissionAsks, 1);
      expect(await nudges.launchedByNudge(), isTrue);
    });

    test('emits a tap', () async {
      final FakeNudges nudges = FakeNudges();
      addTearDown(nudges.dispose);
      final Future<void> tapped = nudges.taps.first;
      nudges.tap();
      await expectLater(tapped, completes);
    });
  });
}
