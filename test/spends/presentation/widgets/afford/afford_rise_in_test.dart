import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/design/hisaab_motion.dart';
import 'package:hisaab/spends/presentation/widgets/afford/afford_rise_in.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/pump_app.dart';

/// The answer rising in (UI_DESIGN 5.4a): like Spends' pages, a crossfade only under reduced motion.
void main() {
  const Key line = ValueKey<String>('answer');
  final Finder answer = find.byKey(line);

  Future<void> pumpRise(WidgetTester tester, {required bool reduceMotion}) => pumpApp(
    tester,
    const Center(
      child: AffordRiseIn(child: SizedBox(key: line, width: 200, height: 80)),
    ),
    reduceMotion: reduceMotion,
    settle: false,
  );

  Finder inRise(Type type) => find.descendant(of: find.byType(AffordRiseIn), matching: find.byType(type));

  double opacity(WidgetTester tester) => tester.widget<FadeTransition>(inRise(FadeTransition)).opacity.value;

  double belowRest(WidgetTester tester) => tester.getCenter(answer).dy - tester.getCenter(find.byType(AffordRiseIn)).dy;

  group('AffordRiseIn', () {
    testWidgets('rises a quarter of its height and fades in, then rests in place', (WidgetTester tester) async {
      await pumpRise(tester, reduceMotion: false);
      expect(belowRest(tester), closeTo(80 * AffordRiseIn.rise, 0.01));
      expect(opacity(tester), 0);

      await tester.pump(const Duration(milliseconds: 100));
      expect(belowRest(tester), allOf(greaterThan(0), lessThan(80 * AffordRiseIn.rise)));

      await tester.pumpAndSettle();
      expect(opacity(tester), 1);
      expect(belowRest(tester), 0);
    });

    testWidgets('with reduced motion it only crossfades, in 150 ms, with no movement', (WidgetTester tester) async {
      await pumpRise(tester, reduceMotion: true);
      final Offset start = tester.getTopLeft(answer);

      expect(inRise(SlideTransition), findsNothing);
      expect(belowRest(tester), 0);
      await tester.pump(HisaabMotion.reducedCrossfade ~/ 2);
      expect(tester.getTopLeft(answer), start);
      expect(opacity(tester), closeTo(0.5, 0.01));

      await tester.pump(HisaabMotion.reducedCrossfade ~/ 2);
      expect(opacity(tester), 1);
      expect(tester.getTopLeft(answer), start);
    });
  });
}
