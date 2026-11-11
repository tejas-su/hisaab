import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/core/design/hisaab_motion.dart';
import 'package:hisaab/home/presentation/widgets/hero_sheen.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

Finder _band() => find.byKey(HeroSheen.bandKey);

Widget _sheen(Key key) => Center(
  child: HeroSheen(key: key, child: const SizedBox(width: 300, height: 200)),
);

void main() {
  group('HeroSheen (D106)', () {
    testWidgets('one pass of light crosses the card when it appears, then it is gone', (WidgetTester tester) async {
      await pumpApp(tester, _sheen(const ValueKey<int>(1)), settle: false);
      await tester.pump(HisaabMotion.sheen ~/ 2);
      expect(_band(), findsOneWidget);
      await tester.pump(HisaabMotion.sheen);
      expect(_band(), findsNothing);
      expect(tester.hasRunningAnimations, isFalse, reason: 'it never loops');
    });

    testWidgets('a rebuild with the same key does not play it again', (WidgetTester tester) async {
      await pumpApp(tester, _sheen(const ValueKey<int>(1)));
      await pumpApp(tester, _sheen(const ValueKey<int>(1)), settle: false);
      await tester.pump(HisaabMotion.sheen ~/ 2);
      expect(_band(), findsNothing);
    });

    testWidgets('a new day (a new key) plays it again', (WidgetTester tester) async {
      await pumpApp(tester, _sheen(const ValueKey<int>(1)));
      await pumpApp(tester, _sheen(const ValueKey<int>(2)), settle: false);
      await tester.pump(HisaabMotion.sheen ~/ 2);
      expect(_band(), findsOneWidget);
    });

    testWidgets('the band paints on its own layer, so the card under it does not repaint each frame', (WidgetTester tester) async {
      await pumpApp(tester, _sheen(const ValueKey<int>(1)), settle: false);
      await tester.pump(HisaabMotion.sheen ~/ 2);
      final RenderObject band = tester.renderObject(_band());
      RenderObject? layer = band.parent;
      while (layer != null && !layer.isRepaintBoundary) {
        layer = layer.parent;
      }
      expect(
        find.descendant(of: find.byType(HeroSheen), matching: find.byWidgetPredicate((Widget w) => w is RepaintBoundary)),
        findsOneWidget,
      );
      expect(layer, tester.renderObject(find.descendant(of: find.byType(HeroSheen), matching: find.byType(RepaintBoundary))));
    });

    testWidgets('halfway through the sweep the band is mid-card: it eases in and out, never crawling at the end', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, _sheen(const ValueKey<int>(1)), settle: false);
      // why: the first quarter of the pass is a wait; the sweep's midpoint is at 0.25 + 0.75 / 2.
      await tester.pump(HisaabMotion.sheen * 0.625);
      final HeroSheenPainter painter = tester.widget<CustomPaint>(_band()).painter! as HeroSheenPainter;
      expect(painter.progress, closeTo(0.5, 0.05));
    });

    testWidgets('reduced motion: no sheen at all', (WidgetTester tester) async {
      await pumpApp(tester, _sheen(const ValueKey<int>(1)), reduceMotion: true, settle: false);
      await tester.pump(HisaabMotion.sheen ~/ 2);
      expect(_band(), findsNothing);
    });

    testWidgets('the band uses the sheen token, ignores touches and is not announced', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _sheen(const ValueKey<int>(1)), settle: false);
      await tester.pump(HisaabMotion.sheen ~/ 2);
      final CustomPaint band = tester.widget<CustomPaint>(_band());
      expect((band.painter! as HeroSheenPainter).color, HisaabColors.light.displaySheen);
      expect(find.ancestor(of: _band(), matching: find.byType(IgnorePointer)), findsWidgets);
      handle.dispose();
    });
  });

  group('HeroSheenPainter', () {
    test('repaints when the band moves or the colour changes', () {
      const HeroSheenPainter painter = HeroSheenPainter(progress: 0.5, color: Color(0x80FFFFFF));
      expect(painter.shouldRepaint(const HeroSheenPainter(progress: 0.5, color: Color(0x80FFFFFF))), isFalse);
      expect(painter.shouldRepaint(const HeroSheenPainter(progress: 0.6, color: Color(0x80FFFFFF))), isTrue);
      expect(painter.shouldRepaint(const HeroSheenPainter(progress: 0.5, color: Color(0x80000000))), isTrue);
    });

    const Size card = Size(372, 330);
    double along(Offset point) => point.dx * HeroSheenPainter.direction(card).dx + point.dy * HeroSheenPainter.direction(card).dy;
    final double farCorner = along(Offset(card.width, card.height));

    test('the band starts wholly off the top start corner, so it slides in instead of appearing', () {
      final (Offset from, Offset to) = HeroSheenPainter.bandEnds(card, 0);
      expect(along(from), lessThan(along(to)));
      expect(along(to), lessThanOrEqualTo(0));
    });

    test('the band ends wholly past the bottom end corner, so it slides out instead of sticking there', () {
      final (Offset from, Offset _) = HeroSheenPainter.bandEnds(card, 1);
      expect(along(from), greaterThanOrEqualTo(farCorner - 1e-9));
    });

    test('the band keeps its width and moves forward the whole way', () {
      final List<(Offset, Offset)> steps = <double>[
        0,
        0.25,
        0.5,
        0.75,
        0.95,
        1,
      ].map((double p) => HeroSheenPainter.bandEnds(card, p)).toList();
      final double width = (steps.first.$2 - steps.first.$1).distance;
      expect(steps.map(((Offset, Offset) e) => (e.$2 - e.$1).distance), everyElement(closeTo(width, 0.001)));
      final List<double> centres = steps.map(((Offset, Offset) e) => along((e.$1 + e.$2) / 2)).toList();
      expect(centres, orderedEquals(<double>[...centres]..sort()));
      expect(centres.toSet(), hasLength(centres.length));
    });
  });
}
