import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/design/hisaab_motion.dart';
import 'package:hisaab/spends/presentation/widgets/story_reveal.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpReveal(WidgetTester tester, {bool reduceMotion = false}) => pumpApp(
        tester,
        const Scaffold(body: StoryReveal(children: <Widget>[Text('first'), Text('second'), Text('third')])),
        reduceMotion: reduceMotion,
        settle: false,
      );

  double opacityOf(WidgetTester tester, String text) =>
      tester.widget<FadeTransition>(find.ancestor(of: find.text(text), matching: find.byType(FadeTransition)).first).opacity.value;

  group('StoryReveal', () {
    testWidgets('lines rise in one after another, then all rest in place', (WidgetTester tester) async {
      await pumpReveal(tester);
      expect(opacityOf(tester, 'first'), 0);
      await tester.pump(HisaabMotion.storyStagger * 2);
      expect(opacityOf(tester, 'first'), greaterThan(opacityOf(tester, 'third')));
      await tester.pumpAndSettle();
      expect(opacityOf(tester, 'first'), 1);
      expect(opacityOf(tester, 'third'), 1);
    });

    testWidgets('with reduced motion every line is in place from the first frame', (WidgetTester tester) async {
      await pumpReveal(tester, reduceMotion: true);
      expect(opacityOf(tester, 'first'), 1);
      expect(opacityOf(tester, 'third'), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('keeps its place when rebuilt', (WidgetTester tester) async {
      await pumpReveal(tester);
      await tester.pumpAndSettle();
      await pumpReveal(tester);
      expect(opacityOf(tester, 'second'), 1);
    });
  });
}
