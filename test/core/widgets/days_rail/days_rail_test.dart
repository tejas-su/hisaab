import 'dart:ui' as ui;

import 'package:hisaab/core/design/app_icon.dart';
import 'package:hisaab/core/widgets/days_rail/days_rail.dart';
import 'package:hisaab/core/widgets/days_rail/days_rail_data.dart';
import 'package:hisaab/core/widgets/days_rail/days_rail_painter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

const DaysRailData _nine = DaysRailData(count: 9, style: DaysRailStyle.onTrack);

const DaysRailColors _colors = DaysRailColors(
  signal: Color(0xFFFFB020),
  idle: Color(0xFFD7CFC5),
  edge: Color(0xFF161615),
  ink2: Color(0xFF65605A),
  card: Color(0xFFFFFEFC),
);

DaysRailPainter _painterIn(WidgetTester tester) => tester
    .widget<CustomPaint>(find.descendant(of: find.byType(DaysRail), matching: find.byType(CustomPaint)))
    .painter! as DaysRailPainter;

void _paintOnce(DaysRailPainter painter) {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), const Size(234, 18));
  recorder.endRecording().dispose();
}

Widget _rail({bool assemble = false}) => Center(
      child: SizedBox(
        width: 288,
        child: DaysRail(data: _nine, todayCaption: 'Today', laterCaption: '9 days to payday', payday: '7 Nov', assemble: assemble),
      ),
    );

void main() {
  group('DaysRail (BR-6)', () {
    testWidgets('dots, then the payday flag and date at the end; captions under the dots', (WidgetTester tester) async {
      await pumpApp(tester, _rail());
      final Rect dots = tester.getRect(find.descendant(of: find.byType(DaysRail), matching: find.byType(CustomPaint)));
      final Rect flag = tester.getRect(find.byType(AppIcon));
      expect(flag.left - dots.right, DaysRail.flagGap);
      expect(tester.getRect(find.text('7 Nov')).right, tester.getRect(find.byType(DaysRail)).right);
      expect(tester.getRect(find.text('Today')).left, dots.left);
      expect(tester.getRect(find.text('9 days to payday')).right, dots.right);
    });

    testWidgets('after onboarding the dots arrive one by one, then rest', (WidgetTester tester) async {
      await pumpApp(tester, _rail(assemble: true), settle: false);
      expect(_painterIn(tester).arrived, 0);
      await tester.pumpAndSettle();
      expect(_painterIn(tester).arrived, 1);
    });

    testWidgets('with reduced motion the dots are there at once', (WidgetTester tester) async {
      await pumpApp(tester, _rail(assemble: true), reduceMotion: true, settle: false);
      expect(_painterIn(tester).arrived, 1);
    });

    testWidgets('without assemble the dots are there at once', (WidgetTester tester) async {
      await pumpApp(tester, _rail(), settle: false);
      expect(_painterIn(tester).arrived, 1);
    });
  });

  group('DaysRailPainter (BR-5)', () {
    for (final DaysRailStyle style in DaysRailStyle.values) {
      test('paints today\'s dot $style', () {
        expect(() => _paintOnce(DaysRailPainter(data: DaysRailData(count: 9, style: style), colors: _colors)), returnsNormally);
      });
    }

    test('paints a single dot on the last day, and partly arrived dots, with no edge in dark', () {
      const DaysRailColors dark = DaysRailColors(
        signal: Color(0xFFFFB020),
        idle: Color(0xFF413D38),
        edge: Color(0x00000000),
        ink2: Color(0xFFA7A199),
        card: Color(0xFF211F1C),
      );
      expect(() => _paintOnce(const DaysRailPainter(data: DaysRailData(count: 1, style: DaysRailStyle.onTrack), colors: dark)), returnsNormally);
      expect(() => _paintOnce(const DaysRailPainter(data: _nine, colors: dark, arrived: 0.3)), returnsNormally);
    });

    test('repaints only when what it draws changes', () {
      const DaysRailPainter painter = DaysRailPainter(data: _nine, colors: _colors);
      expect(painter.shouldRepaint(const DaysRailPainter(data: _nine, colors: _colors)), isFalse);
      expect(painter.shouldRepaint(const DaysRailPainter(data: DaysRailData(count: 8, style: DaysRailStyle.onTrack), colors: _colors)), isTrue);
      expect(painter.shouldRepaint(const DaysRailPainter(data: _nine, colors: _colors, arrived: 0.5)), isTrue);
    });
  });

  testWidgets('a 62-day bridge cycle (BR-1a, D140) still fits on a 320dp phone', (WidgetTester tester) async {
    await pumpApp(
      tester,
      const Center(
        child: DaysRail(
          data: DaysRailData(count: 62, style: DaysRailStyle.onTrack),
          todayCaption: 'Today',
          laterCaption: '62 days to payday',
          payday: '25 Dec',
        ),
      ),
      size: TestWindows.smallPhone,
    );
    expect(tester.takeException(), isNull);
    expect(() => _paintOnce(const DaysRailPainter(data: DaysRailData(count: 62, style: DaysRailStyle.onTrack), colors: _colors)), returnsNormally);
  });
}
