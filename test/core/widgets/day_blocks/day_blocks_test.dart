import 'package:expense_tracker/core/widgets/day_blocks/day_blocks.dart';
import 'package:expense_tracker/core/widgets/day_blocks/day_blocks_data.dart';
import 'package:expense_tracker/core/widgets/day_blocks/day_blocks_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

class _Host extends StatelessWidget {
  const _Host(this.data, {this.assemble = false, this.width = 320});

  final DayBlocksData data;
  final bool assemble;
  final double width;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SizedBox(width: width, child: DayBlocks(data: data, semanticLabel: '9 days to payday', assemble: assemble)),
        ),
      );
}

DayBlocksPainter _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(find.descendant(of: find.byType(DayBlocks), matching: find.byType(CustomPaint)))
    .painter! as DayBlocksPainter;

void main() {
  group('DayBlocks', () {
    for (final DayBlocksStyle style in DayBlocksStyle.values) {
      testWidgets('paints the ${style.name} style', (WidgetTester tester) async {
        await pumpApp(tester, _Host(DayBlocksData(count: 9, style: style, todayFill: 0.3, laterHeight: 0.6)));
        expect(_painter(tester).data.style, style);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('announces one label, not each block', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, const _Host(DayBlocksData(count: 9, style: DayBlocksStyle.onTrack)));
      expect(find.bySemanticsLabel('9 days to payday'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('animates between values and settles on the target', (WidgetTester tester) async {
      final ValueNotifier<DayBlocksData> data = ValueNotifier<DayBlocksData>(const DayBlocksData(count: 9, style: DayBlocksStyle.onTrack));
      addTearDown(data.dispose);
      await pumpApp(
        tester,
        ValueListenableBuilder<DayBlocksData>(valueListenable: data, builder: (BuildContext _, DayBlocksData d, Widget? _) => _Host(d)),
      );
      data.value = const DayBlocksData(count: 9, style: DayBlocksStyle.onTrack, todayFill: 0.2, laterHeight: 0.5);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(_painter(tester).data.todayFill, inExclusiveRange(0.2, 1));
      await tester.pumpAndSettle();
      expect(_painter(tester).data.todayFill, closeTo(0.2, 0.01));
    });

    testWidgets('reduced motion jumps straight to the new values', (WidgetTester tester) async {
      final ValueNotifier<DayBlocksData> data = ValueNotifier<DayBlocksData>(const DayBlocksData(count: 9, style: DayBlocksStyle.onTrack));
      addTearDown(data.dispose);
      await pumpApp(
        tester,
        ValueListenableBuilder<DayBlocksData>(valueListenable: data, builder: (BuildContext _, DayBlocksData d, Widget? _) => _Host(d)),
        reduceMotion: true,
      );
      data.value = const DayBlocksData(count: 9, style: DayBlocksStyle.onTrack, todayFill: 0.2);
      await tester.pump();
      expect(_painter(tester).data.todayFill, 0.2);
    });

    testWidgets('assembles in, block by block, after onboarding', (WidgetTester tester) async {
      await pumpApp(tester, const _Host(DayBlocksData(count: 9, style: DayBlocksStyle.onTrack), assemble: true), settle: false);
      await tester.pump(const Duration(milliseconds: 100));
      expect(_painter(tester).assembled, inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      expect(_painter(tester).assembled, closeTo(1, 0.01));
    });

    testWidgets('a long cycle in a narrow row collapses to 7 blocks and a +N label', (WidgetTester tester) async {
      await pumpApp(tester, const _Host(DayBlocksData(count: 31, style: DayBlocksStyle.onTrack), width: 150));
      expect(_painter(tester).moreLabel.text?.toPlainText(), '+31');
      expect(tester.takeException(), isNull);
    });

    group('today’s edge', () {
      const Color edge = Color(0xFF161615);
      const DayBlocksColors colors =
          DayBlocksColors(signal: Color(0xFFFFB020), idle: Color(0xFFD3D0C8), outline: Color(0xFF62615C), edge: edge);
      final TextPainter label = TextPainter(text: const TextSpan(text: '+9'), textDirection: TextDirection.ltr)..layout();
      tearDownAll(label.dispose);

      PaintPatternPredicate strokeOf(Color color) => (Symbol method, List<dynamic> arguments) {
            final Object? paint = arguments.length > 1 ? arguments[1] : null;
            return method == #drawRRect && paint is Paint && paint.style == PaintingStyle.stroke && paint.color.toARGB32() == color.toARGB32();
          };

      void Function(Canvas) paintStyle(DayBlocksStyle style) => (Canvas canvas) =>
          DayBlocksPainter(data: DayBlocksData(count: 9, style: style, todayFill: 0.2), colors: colors, moreLabel: label)
              .paint(canvas, const Size(320, 40));

      for (final DayBlocksStyle style in <DayBlocksStyle>[DayBlocksStyle.onTrack, DayBlocksStyle.preview, DayBlocksStyle.slowDown]) {
        test('outlines marigold in ${style.name}', () {
          expect(paintStyle(style), paints..something(strokeOf(edge)));
        });
      }

      test('keeps the marigold ring inside the edge in slowDown', () {
        expect(
          paintStyle(DayBlocksStyle.slowDown),
          paints
            ..something(strokeOf(const Color(0xFFFFB020)))
            ..something(strokeOf(edge)),
        );
      });

      for (final DayBlocksStyle style in <DayBlocksStyle>[DayBlocksStyle.overToday, DayBlocksStyle.overCycle]) {
        test('is not drawn in ${style.name}, where no marigold shows', () {
          expect(paintStyle(style), isNot(paints..something(strokeOf(edge))));
        });
      }

      test('without an edge, the slowDown ring stays at the block’s rim', () {
        const DayBlocksColors noEdge = DayBlocksColors(signal: Color(0xFFFFB020), idle: Color(0xFF3A3A37), outline: Color(0xFF9C9B95));
        expect(
          (Canvas canvas) => DayBlocksPainter(
            data: const DayBlocksData(count: 9, style: DayBlocksStyle.slowDown, todayFill: 0.2),
            colors: noEdge,
            moreLabel: label,
          ).paint(canvas, const Size(320, 40)),
          paints
            ..something((Symbol method, List<dynamic> arguments) {
              final Object? shape = arguments.isEmpty ? null : arguments.first;
              return method == #drawRRect && shape is RRect && shape.left == 0.75 && shape.top == 0.75;
            }),
        );
      });
    });

    test('repaints only when its inputs change', () {
      final TextPainter label = TextPainter(text: const TextSpan(text: '+9'), textDirection: TextDirection.ltr);
      const DayBlocksColors colors = DayBlocksColors(signal: Color(0xFFFFB020), idle: Color(0xFF3A3A37), outline: Color(0xFF9C9B95));
      const DayBlocksData data = DayBlocksData(count: 9, style: DayBlocksStyle.onTrack);
      final DayBlocksPainter painter = DayBlocksPainter(data: data, colors: colors, moreLabel: label);
      expect(painter.shouldRepaint(DayBlocksPainter(data: data, colors: colors, moreLabel: label)), isFalse);
      expect(
        painter.shouldRepaint(
          DayBlocksPainter(data: const DayBlocksData(count: 8, style: DayBlocksStyle.onTrack), colors: colors, moreLabel: label),
        ),
        isTrue,
      );
      expect(painter.shouldRepaint(DayBlocksPainter(data: data, colors: colors, moreLabel: label, assembled: 0.5)), isTrue);
      label.dispose();
    });
  });
}
