import 'package:expense_tracker/core/design/hisaab_motion.dart';
import 'package:expense_tracker/home/presentation/widgets/hero_press.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

double _scale(WidgetTester tester) => tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

void main() {
  group('HeroPress (D106)', () {
    late int taps;

    setUp(() => taps = 0);

    Widget press() => Center(child: HeroPress(onTap: () => taps++, child: const SizedBox(width: 300, height: 200)));

    testWidgets('the card sinks while a finger is down and comes back on release', (WidgetTester tester) async {
      await pumpApp(tester, press());
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(HeroPress)));
      await tester.pump();
      expect(_scale(tester), HisaabMotion.pressedScale);
      await gesture.up();
      await tester.pump();
      expect(_scale(tester), 1);
      expect(taps, 1);
    });

    testWidgets('a drag away cancels the press without a tap', (WidgetTester tester) async {
      await pumpApp(tester, press());
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.byType(HeroPress)));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 300));
      await gesture.up();
      await tester.pump();
      expect(_scale(tester), 1);
      expect(taps, 0);
    });

    testWidgets('reduced motion: the press shows at once, with no animation', (WidgetTester tester) async {
      await pumpApp(tester, press(), reduceMotion: true);
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).duration, Duration.zero);
    });
  });
}
