import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/spends/presentation/widgets/day_bars.dart';
import 'package:hisaab/spends/presentation/widgets/day_bars_painter.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';

void main() {
  final DayBarsData data = (perDay: <int>[0, 50000, 200000, 0, 90000, 0, 30000, 10000, 40000, 0], share: 100000, marked: <int>{2, 9});

  Future<void> pump(WidgetTester tester, {required int peakIndex, DayBarsData? bars}) => pumpApp(
        tester,
        Scaffold(
          body: SizedBox(
            width: 320,
            child: DayBars(data: bars ?? data, height: 150, peakIndex: peakIndex, dates: ('4 Sept', '6 Sept', '13 Sept')),
          ),
        ),
      );

  group('DayBars (FR-SP-7 AC-4, D194)', () {
    testWidgets('names the first, the biggest and the last day', (WidgetTester tester) async {
      await pump(tester, peakIndex: 4);
      expect(find.text('4 Sept'), findsOneWidget);
      expect(find.text('6 Sept'), findsOneWidget);
      expect(find.text('13 Sept'), findsOneWidget);
    });

    testWidgets('drops the biggest day when it would touch an end', (WidgetTester tester) async {
      await pump(tester, peakIndex: 0);
      expect(find.text('6 Sept'), findsNothing);
      await pump(tester, peakIndex: 9);
      expect(find.text('6 Sept'), findsNothing);
    });

    testWidgets('is hidden from screen readers', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pump(tester, peakIndex: 4);
      expect(find.bySemanticsLabel('4 Sept'), findsNothing);
      semantics.dispose();
    });

    testWidgets('paints with no share and with nothing spent', (WidgetTester tester) async {
      await pump(tester, peakIndex: 4, bars: (perDay: data.perDay, share: null, marked: const <int>{}));
      await pump(tester, peakIndex: 4, bars: (perDay: <int>[0, 0, 0], share: null, marked: const <int>{}));
      expect(tester.takeException(), isNull);
    });
  });

  group('DayBarsPainter', () {
    const Color ink = Color(0xFF000000);
    const Color ink2 = Color(0xFF777777);

    test('repaints only when its inputs change', () {
      final DayBarsPainter painter = DayBarsPainter(data: data, ink: ink, ink2: ink2, axis: ink2);
      expect(painter.shouldRepaint(DayBarsPainter(data: data, ink: ink, ink2: ink2, axis: ink2)), isFalse);
      expect(painter.shouldRepaint(DayBarsPainter(data: data, ink: ink2, ink2: ink2, axis: ink2)), isTrue);
    });
  });
}
