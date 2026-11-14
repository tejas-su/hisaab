import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/design/hisaab_motion.dart';
import 'package:hisaab/home/presentation/widgets/today_row_reveal.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';

/// A new *Not logged* row grows into the Today list after the hero has rolled, so a figure is read
/// before the list shifts (SPEC FR-FX-5 AC-2, E13).
void main() {
  const ValueKey<String> row = ValueKey<String>('row');

  Widget host({required bool delayed}) =>
      Scaffold(body: Column(children: <Widget>[TodayRowReveal(delayed: delayed, child: const SizedBox(key: row, height: 60, width: 100))]));

  group('TodayRowReveal', () {
    testWidgets('an ordinary row is there at once', (WidgetTester tester) async {
      await pumpApp(tester, host(delayed: false));

      expect(tester.getSize(find.byKey(row)).height, 60);
      expect(tester.getSize(find.byType(TodayRowReveal)).height, 60);
    });

    testWidgets('a fix row takes no room until the hero has rolled, then grows in', (WidgetTester tester) async {
      await pumpApp(tester, host(delayed: true), settle: false);
      await tester.pump();

      expect(tester.getSize(find.byType(TodayRowReveal)).height, 0);
      await tester.pump(HisaabMotion.numberRoll - const Duration(milliseconds: 10));
      expect(tester.getSize(find.byType(TodayRowReveal)).height, 0);

      await tester.pump(const Duration(milliseconds: 20));
      await tester.pump(HisaabMotion.resize);
      expect(tester.getSize(find.byType(TodayRowReveal)).height, 60);
    });

    testWidgets('under reduced motion the row has its height at once and fades in over 150 ms, with no delay', (WidgetTester tester) async {
      await pumpApp(tester, host(delayed: true), reduceMotion: true, settle: false);
      await tester.pump();

      expect(tester.getSize(find.byType(TodayRowReveal)).height, 60);
      expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).duration, HisaabMotion.reducedCrossfade);
      await tester.pumpAndSettle();
    });

    testWidgets('the duration does not depend on the size of the change: the delay is one token', (WidgetTester tester) async {
      expect(TodayRowReveal.delay, HisaabMotion.numberRoll);
    });
  });
}
