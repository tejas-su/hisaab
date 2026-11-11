import 'dart:ui' as ui;

import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/core/widgets/display_card.dart';
import 'package:hisaab/core/widgets/display_etch.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

ShapeDecoration _decoration(WidgetTester tester) =>
    tester.widget<Container>(find.descendant(of: find.byType(DisplayCard), matching: find.byType(Container)).first).decoration!
        as ShapeDecoration;

void main() {
  group('DisplayCard', () {
    testWidgets('is flat and plain by default', (WidgetTester tester) async {
      await pumpApp(tester, const DisplayCard(child: Text('x')));
      expect(_decoration(tester).shadows, isNull);
      expect(find.byType(DisplayEtch), findsNothing);
    });

    testWidgets('raised: casts the display shadow (D106)', (WidgetTester tester) async {
      await pumpApp(tester, const DisplayCard(raised: true, child: Text('x')));
      final List<BoxShadow> shadows = _decoration(tester).shadows!;
      expect(shadows, hasLength(1));
      expect(shadows.single.color, HisaabColors.light.displayShadow);
      expect(shadows.single.blurRadius, greaterThan(0));
    });

    testWidgets('etched: draws the etch behind the content, clipped to the card', (WidgetTester tester) async {
      await pumpApp(tester, const DisplayCard(etched: true, child: Text('x')));
      expect(find.byType(DisplayEtch), findsOneWidget);
      expect(find.text('x'), findsOneWidget);
      final Container card = tester.widget<Container>(
        find.descendant(of: find.byType(DisplayCard), matching: find.byType(Container)).first,
      );
      expect(card.clipBehavior, Clip.antiAlias);
      expect(tester.getSize(find.byType(DisplayEtch)), tester.getSize(find.byType(DisplayCard)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('etched: the content keeps the shared side inset, with more room above and below the border (D107)', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, const Center(child: DisplayCard(etched: true, child: SizedBox(width: 100, height: 10))));
      final Rect card = tester.getRect(find.byType(DisplayCard));
      final Rect content = tester.getRect(find.byType(SizedBox).last);
      expect(content.left - card.left, 20);
      expect(content.top - card.top, 24);
      expect(card.bottom - content.bottom, 24);
    });
  });

  group('DisplayEtchPainter', () {
    const Size card = Size(372, 261);

    test('the rosette sits near the top end corner, mirrored in right-to-left', () {
      expect(DisplayEtchPainter.rosetteCentre(card, TextDirection.ltr), const Offset(292, 60));
      expect(DisplayEtchPainter.rosetteCentre(card, TextDirection.rtl), const Offset(80, 60));
    });

    test('repaints only when its colour or direction changes', () {
      const DisplayEtchPainter painter = DisplayEtchPainter(
        color: Color(0xFFEEECE6),
        frame: Color(0xFFD3D0C8),
        textDirection: TextDirection.ltr,
      );
      expect(
        painter.shouldRepaint(
          const DisplayEtchPainter(color: Color(0xFFEEECE6), frame: Color(0xFFD3D0C8), textDirection: TextDirection.ltr),
        ),
        isFalse,
      );
      expect(
        painter.shouldRepaint(
          const DisplayEtchPainter(color: Color(0xFF2C2C29), frame: Color(0xFFD3D0C8), textDirection: TextDirection.ltr),
        ),
        isTrue,
      );
      expect(
        painter.shouldRepaint(
          const DisplayEtchPainter(color: Color(0xFFEEECE6), frame: Color(0xFFD3D0C8), textDirection: TextDirection.rtl),
        ),
        isTrue,
      );
      expect(
        painter.shouldRepaint(
          const DisplayEtchPainter(color: Color(0xFFEEECE6), frame: Color(0xFF373734), textDirection: TextDirection.ltr),
        ),
        isTrue,
      );
    });

    test('the note border runs 6dp inside the card edge, 14dp clear of the content', () {
      expect(DisplayEtchPainter.frameRect(card), const Rect.fromLTRB(6, 6, 366, 255));
    });

    test('inside it, a dashed line runs 10dp in: dashes and gaps alternate all the way round (D107)', () {
      expect(DisplayEtchPainter.dashedFrameRect(card), const Rect.fromLTRB(10, 10, 362, 251));
      final List<ui.PathMetric> dashes = DisplayEtchPainter.dashedFramePath(card).computeMetrics().toList();
      expect(dashes.length, greaterThan(100));
      // why: a dash on a corner re-measures up to ~0.7dp long after flattening, but stays under 5,
      // so no dash runs into the next.
      expect(dashes.every((ui.PathMetric dash) => dash.length < 5), isTrue);
    });

    test('the outer note border is one solid line all the way round (D107)', () {
      final List<ui.PathMetric> contours = DisplayEtchPainter.framePath(card).computeMetrics().toList();
      expect(contours, hasLength(1));
      expect(contours.single.isClosed, isTrue);
      // why: a 360 × 249 squircle with 22dp corners is a little under its rectangle's 1,218dp.
      expect(contours.single.length, closeTo(1185, 40));
    });

    testWidgets('dark: uses the dark etch token', (WidgetTester tester) async {
      await pumpApp(tester, const DisplayCard(etched: true, child: Text('x')), themeMode: ThemeMode.dark);
      final CustomPaint paint = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(DisplayEtch), matching: find.byType(CustomPaint)),
      );
      expect((paint.painter! as DisplayEtchPainter).color, HisaabColors.dark.displayEtch);
      expect((paint.painter! as DisplayEtchPainter).frame, HisaabColors.dark.hairline);
      expect((paint.painter! as DisplayEtchPainter).color, HisaabColors.dark.displayEtch, reason: 'the solid line shares the etch colour');
    });
  });
}
