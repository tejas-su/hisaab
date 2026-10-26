import 'package:expense_tracker/app/widgets/midnight_listener.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes/fake_clock.dart';

void main() {
  late FakeClock clock;
  late int newDays;

  setUp(() {
    clock = FakeClock(DateTime(2026, 10, 26, 23, 59));
    newDays = 0;
  });

  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        MidnightListener(clock: clock, onNewDay: () => newDays++, child: const SizedBox()),
      );

  Future<void> passTime(WidgetTester tester, Duration duration) async {
    clock.advance(duration);
    await tester.pump(duration);
  }

  group('MidnightListener (BR-8)', () {
    testWidgets('does nothing before midnight', (WidgetTester tester) async {
      await pump(tester);
      await passTime(tester, const Duration(seconds: 59));
      expect(newDays, 0);
    });

    testWidgets('fires once just after local midnight', (WidgetTester tester) async {
      await pump(tester);
      await passTime(tester, const Duration(minutes: 1, seconds: 1));
      expect(newDays, 1);
    });

    testWidgets('fires again the next midnight', (WidgetTester tester) async {
      await pump(tester);
      await passTime(tester, const Duration(minutes: 1, seconds: 1));
      await passTime(tester, const Duration(hours: 23, minutes: 59));
      expect(newDays, 1);
      await passTime(tester, const Duration(minutes: 1));
      expect(newDays, 2);
    });

    testWidgets('re-times itself on resume, e.g. after the phone slept', (WidgetTester tester) async {
      await pump(tester);
      clock.current = DateTime(2026, 10, 27, 23, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(minutes: 2));
      expect(newDays, 0, reason: 'the old timer for the 26th was replaced');
      await passTime(tester, const Duration(hours: 1, seconds: 1));
      expect(newDays, 1);
    });

    testWidgets('stops when removed', (WidgetTester tester) async {
      await pump(tester);
      await tester.pumpWidget(const SizedBox());
      await passTime(tester, const Duration(minutes: 2));
      expect(newDays, 0);
    });
  });
}
