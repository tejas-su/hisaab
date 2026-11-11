import 'dart:ui' as ui;

import 'package:hisaab/core/widgets/today_bar/today_bar.dart';
import 'package:hisaab/core/widgets/today_bar/today_bar_data.dart';
import 'package:hisaab/core/widgets/today_bar/today_bar_painter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

const TodayBarData _lunch = TodayBarData(
  style: TodayBarStyle.onTrack,
  left: 1430 / 1850,
  bites: <TodayBite>[TodayBite(share: 40 / 1850, label: 'Chai'), TodayBite(share: 380 / 1850, label: 'Food')],
);

const TodayBarData _groceries = TodayBarData(
  style: TodayBarStyle.slowDown,
  left: 350 / 1850,
  bites: <TodayBite>[
    TodayBite(share: 40 / 1850, label: 'Chai'),
    TodayBite(share: 380 / 1850, label: 'Food'),
    TodayBite(share: 1080 / 1850, label: 'Groceries'),
  ],
);

const TodayBarColors _colors = TodayBarColors(
  signal: Color(0xFFFFB020),
  idle: Color(0xFFD7CFC5),
  edge: Color(0xFF161615),
  ink: Color(0xFF161615),
  ink2: Color(0xFF65605A),
  card: Color(0xFFFFFEFC),
);

TodayBarPainter _painterIn(WidgetTester tester) => tester
    .widget<CustomPaint>(find.descendant(of: find.byType(TodayBar), matching: find.byType(CustomPaint)))
    .painter! as TodayBarPainter;

void _paintOnce(TodayBarPainter painter) {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), const Size(288, 66));
  recorder.endRecording().dispose();
}

class _Host extends StatelessWidget {
  const _Host(this.data, {this.fillIn = false});

  final TodayBarData data;
  final bool fillIn;

  @override
  Widget build(BuildContext context) => Center(child: SizedBox(width: 288, child: TodayBar(data: data, fillIn: fillIn)));
}

void main() {
  group('TodayBar (BR-6)', () {
    testWidgets('is 48dp of bar plus a line of names under it, and silent to TalkBack', (WidgetTester tester) async {
      await pumpApp(tester, const _Host(_lunch));
      expect(tester.getSize(find.byType(TodayBar)).height, TodayBarPainter.barHeight + TodayBarPainter.nameGap + 14);
      expect(find.ancestor(of: find.byType(CustomPaint).last, matching: find.byType(ExcludeSemantics)), findsWidgets);
    });

    testWidgets('fills in from empty when it appears, then rests on the picture', (WidgetTester tester) async {
      await pumpApp(tester, const _Host(_lunch, fillIn: true), settle: false);
      expect(_painterIn(tester).progress, 0);
      expect(_painterIn(tester).from.left, 0);
      await tester.pumpAndSettle();
      expect(_painterIn(tester).progress, 1);
    });

    testWidgets('a new spend moves the yellow from the old picture to the new one on a spring', (WidgetTester tester) async {
      await pumpApp(tester, const _Host(_lunch));
      await pumpApp(tester, const _Host(_groceries), settle: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_painterIn(tester).from, _lunch);
      expect(_painterIn(tester).progress, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(_painterIn(tester).progress, 1);
    });

    testWidgets('with reduced motion it jumps straight to the new picture', (WidgetTester tester) async {
      await pumpApp(tester, const _Host(_lunch, fillIn: true), reduceMotion: true, settle: false);
      expect(_painterIn(tester).progress, 1);
      await pumpApp(tester, const _Host(_groceries), reduceMotion: true, settle: false);
      expect(_painterIn(tester).progress, 1);
    });
  });

  group('TodayBarPainter (BR-5, BR-6)', () {
    final List<(String, TodayBarData)> pictures = <(String, TodayBarData)>[
      ('on track, with names', _lunch),
      ('slow down', _groceries),
      ('over, with the tick and hatch', const TodayBarData(style: TodayBarStyle.over, bites: <TodayBite>[TodayBite(share: 1, label: 'Food')], tick: 0.8)),
      ('empty (A = 0)', const TodayBarData(style: TodayBarStyle.onTrack)),
    ];
    for (final (String name, TodayBarData data) in pictures) {
      test('paints $name', () {
        expect(() => _paintOnce(TodayBarPainter(from: data, to: data, progress: 1, colors: _colors, names: const TextStyle(fontSize: 12))), returnsNormally);
      });
    }

    test('paints with no edge in dark, and mid-move', () {
      final TodayBarColors dark = TodayBarColors(
        signal: _colors.signal,
        idle: _colors.idle,
        edge: const Color(0x00000000),
        ink: _colors.ink,
        ink2: _colors.ink2,
        card: _colors.card,
      );
      expect(() => _paintOnce(TodayBarPainter(from: _lunch, to: _groceries, progress: 0.5, colors: dark, names: const TextStyle())), returnsNormally);
    });

    test('repaints only when what it draws changes', () {
      const TextStyle names = TextStyle(fontSize: 12);
      final TodayBarPainter painter = TodayBarPainter(from: _lunch, to: _lunch, progress: 1, colors: _colors, names: names);
      expect(painter.shouldRepaint(TodayBarPainter(from: _lunch, to: _lunch, progress: 1, colors: _colors, names: names)), isFalse);
      expect(painter.shouldRepaint(TodayBarPainter(from: _lunch, to: _groceries, progress: 1, colors: _colors, names: names)), isTrue);
      expect(painter.shouldRepaint(TodayBarPainter(from: _lunch, to: _lunch, progress: 0.5, colors: _colors, names: names)), isTrue);
      expect(
        painter.shouldRepaint(
          TodayBarPainter(from: _lunch, to: _lunch, progress: 1, colors: _colors, names: names, textScaler: const TextScaler.linear(2)),
        ),
        isTrue,
      );
    });
  });
}
