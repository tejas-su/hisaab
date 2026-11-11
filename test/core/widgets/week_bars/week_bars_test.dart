import 'dart:ui' as ui;

import 'package:hisaab/core/widgets/week_bars/week_bars.dart';
import 'package:hisaab/core/widgets/week_bars/week_bars_data.dart';
import 'package:hisaab/core/widgets/week_bars/week_bars_painter.dart';
import 'package:hisaab/core/widgets/week_bars/week_letters.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

const WeekBarsData _thursday = WeekBarsData(
  bars: <WeekBar>[
    WeekBar(kind: WeekBarKind.past, spent: 0.54, share: 0.79),
    WeekBar(kind: WeekBarKind.past, spent: 1, share: 0.8),
    WeekBar(kind: WeekBarKind.past, spent: 0, share: 0.77),
    WeekBar(kind: WeekBarKind.today, spent: 0.18, share: 0.8),
    WeekBar(kind: WeekBarKind.future),
    WeekBar(kind: WeekBarKind.future),
    WeekBar(kind: WeekBarKind.none),
  ],
  todayIndex: 3,
);

const WeekBarsColors _colors = WeekBarsColors(
  past: Color(0xFF5B5650),
  signal: Color(0xFFFFB020),
  edge: Color(0xFF161615),
  tick: Color(0xFF161615),
  notch: Color(0xFFFFFEFC),
  idle: Color(0xFFD7CFC5),
);

void _paintOnce(WeekBarsPainter painter) {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  painter.paint(Canvas(recorder), const Size(226, 88));
  recorder.endRecording().dispose();
}

class _Host extends StatelessWidget {
  const _Host();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: SizedBox(width: 226, child: WeekBars(data: _thursday, height: 88))));
}

WeekBarsPainter _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.descendant(of: find.byType(WeekBars), matching: find.byType(CustomPaint)))
    .painter! as WeekBarsPainter;

void main() {
  group('WeekBarsPainter (BR-6a)', () {
    test('seven equal columns with 6dp gaps fill the row exactly', () {
      final List<({double left, double width})> columns = <({double left, double width})>[
        for (int i = 0; i < 7; i++) WeekBarsPainter.column(i, 226),
      ];
      expect(columns.first.left, 0);
      expect(columns.last.left + columns.last.width, closeTo(226, 1e-9));
      expect(columns[1].left - (columns[0].left + columns[0].width), closeTo(WeekBarsPainter.gap, 1e-9));
      expect(columns.map((({double left, double width}) c) => c.width).toSet(), hasLength(1));
    });

    test('today rises first, then the columns outward from it', () {
      const WeekBarsPainter early = WeekBarsPainter(data: _thursday, colors: _colors, growth: 0.2);
      expect(early.progressOf(3), greaterThan(early.progressOf(2)));
      expect(early.progressOf(2), early.progressOf(4));
      expect(early.progressOf(0), 0);
    });

    test('fully grown, every column is at full height', () {
      const WeekBarsPainter grown = WeekBarsPainter(data: _thursday, colors: _colors);
      expect(<double>[for (int i = 0; i < 7; i++) grown.progressOf(i)], everyElement(1));
    });

    test('paints every kind of column, at rest and mid-growth, with or without an edge', () {
      const WeekBarsColors noEdge = WeekBarsColors(
        past: Color(0xFFA7A199),
        signal: Color(0xFFFFB020),
        edge: Color(0x00000000),
        tick: Color(0xFFF2F1EC),
        notch: Color(0xFF211F1C),
        idle: Color(0xFF413D38),
      );
      for (final WeekBarsPainter painter in <WeekBarsPainter>[
        const WeekBarsPainter(data: _thursday, colors: _colors),
        const WeekBarsPainter(data: _thursday, colors: noEdge),
        const WeekBarsPainter(data: _thursday, colors: _colors, growth: 0),
        const WeekBarsPainter(data: _thursday, colors: _colors, growth: 0.3),
        const WeekBarsPainter(
          data: WeekBarsData(bars: <WeekBar>[WeekBar(kind: WeekBarKind.today, spent: 1, share: 0.6)], todayIndex: 0),
          colors: _colors,
        ),
      ]) {
        expect(() => _paintOnce(painter), returnsNormally);
      }
    });

    test('repaints only when the data, growth or colours change', () {
      const WeekBarsPainter base = WeekBarsPainter(data: _thursday, colors: _colors);
      expect(base.shouldRepaint(const WeekBarsPainter(data: _thursday, colors: _colors)), isFalse);
      expect(base.shouldRepaint(const WeekBarsPainter(data: _thursday, colors: _colors, growth: 0.5)), isTrue);
      expect(
        base.shouldRepaint(const WeekBarsPainter(data: WeekBarsData(bars: <WeekBar>[], todayIndex: 0), colors: _colors)),
        isTrue,
      );
    });
  });

  group('WeekBar', () {
    test('bars, data and colours compare by value', () {
      expect(const WeekBar(kind: WeekBarKind.past, spent: 0.5, share: 0.8), const WeekBar(kind: WeekBarKind.past, spent: 0.5, share: 0.8));
      expect(const WeekBar(kind: WeekBarKind.past, spent: 0.5), isNot(const WeekBar(kind: WeekBarKind.today, spent: 0.5)));
      expect(const WeekBarsData(bars: <WeekBar>[], todayIndex: 1), isNot(const WeekBarsData(bars: <WeekBar>[], todayIndex: 2)));
      expect(
        _colors,
        isNot(const WeekBarsColors(
          past: Color(0xFF5B5650),
          signal: Color(0xFFFFB020),
          edge: Color(0xFF161615),
          tick: Color(0xFF161615),
          notch: Color(0xFFFFFEFC),
          idle: Color(0xFF000000),
        )),
      );
    });

    test('is over only when it spent more than its share', () {
      expect(const WeekBar(kind: WeekBarKind.past, spent: 0.9, share: 0.8).isOver, isTrue);
      expect(const WeekBar(kind: WeekBarKind.past, spent: 0.8, share: 0.8).isOver, isFalse);
    });
  });

  group('WeekBars', () {
    testWidgets('rise from the baseline on the spring, then rest fully grown', (WidgetTester tester) async {
      await pumpApp(tester, const _Host(), settle: false);
      await tester.pump(const Duration(milliseconds: 50));
      expect(_painter(tester).growth, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(_painter(tester).growth, 1);
    });

    testWidgets('once grown, a later change around them does not start the rise again', (WidgetTester tester) async {
      final ValueNotifier<bool> reduce = ValueNotifier<bool>(false);
      addTearDown(reduce.dispose);
      await pumpApp(
        tester,
        ValueListenableBuilder<bool>(
          valueListenable: reduce,
          builder: (BuildContext context, bool value, Widget? child) =>
              MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: value), child: child!),
          child: const _Host(),
        ),
      );
      reduce.value = true;
      await tester.pump();
      reduce.value = false;
      await tester.pump();
      expect(_painter(tester).growth, 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('with reduced motion they are drawn at once', (WidgetTester tester) async {
      await pumpApp(tester, const _Host(), reduceMotion: true, settle: false);
      expect(_painter(tester).growth, 1);
    });

    testWidgets('carry no semantics of their own (the hero reads one sentence)', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const _Host());
      expect(find.descendant(of: find.byType(WeekBars), matching: find.byType(ExcludeSemantics)), findsOneWidget);
      handle.dispose();
    });
  });

  group('WeekLetters', () {
    testWidgets('each letter is centred on its column, and today\'s is Semibold', (WidgetTester tester) async {
      await pumpApp(
        tester,
        const Scaffold(
          body: Center(
            child: SizedBox(
              width: 226,
              child: WeekLetters(letters: <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'], todayIndex: 3),
            ),
          ),
        ),
      );
      final double rowLeft = tester.getTopLeft(find.byType(WeekLetters)).dx;
      for (int i = 0; i < 7; i++) {
        final ({double left, double width}) column = WeekBarsPainter.column(i, 226);
        expect(tester.getCenter(find.byKey(ValueKey<int>(i))).dx - rowLeft, closeTo(column.left + column.width / 2, 0.01));
      }
      expect(tester.widget<Text>(find.byKey(const ValueKey<int>(3))).style?.fontWeight, FontWeight.w600);
      expect(tester.widget<Text>(find.byKey(const ValueKey<int>(2))).style?.fontWeight, FontWeight.w400);
    });
  });
}
