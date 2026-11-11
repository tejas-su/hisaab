import 'package:hisaab/core/design/hisaab_dimensions.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/pace_series.dart';
import 'package:hisaab/spends/presentation/widgets/pace_card.dart';
import 'package:hisaab/spends/presentation/widgets/pace_chart_painter.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

const PayCycle _cycle = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3));
const CalendarDate _rentDay = CalendarDate(2026, 10, 5);
final List<DatedAmount> _electricity = <DatedAmount>[(date: const CalendarDate(2026, 10, 29), amount: Money.fromMajor(1200))];

Entry _spent(int rupees, CalendarDate date, {int? recurringId}) => Entry(
      id: 200 + date.day,
      amount: Money.fromMajor(rupees),
      kind: EntryKind.spent,
      categoryId: 1,
      date: date,
      createdAt: DateTime(2026, 10, 1),
      recurringId: recurringId,
    );

Option<PaceSeries> _pace(Iterable<Entry> entries, {CalendarDate asOf = WorkedExample.today, bool isCurrent = true, int budget = 45000}) =>
    PaceSeries.of(entries, cycle: _cycle, asOf: asOf, budget: Money.fromMajor(budget), billsDue: _electricity, isCurrent: isCurrent);

final List<Entry> _fast = <Entry>[...WorkedExample.entries, _spent(9000, const CalendarDate(2026, 10, 22))];

void main() {
  Future<void> pump(
    WidgetTester tester,
    Option<PaceSeries> pace, {
    int spent = 27570,
    bool showToday = true,
    Size size = TestWindows.phone,
    double textScale = 1,
  }) =>
      pumpApp(
        tester,
        Scaffold(body: SingleChildScrollView(child: PaceCard(spent: Money.fromMajor(spent), pace: pace, cycle: _cycle, showToday: showToday))),
        size: size,
        textScale: textScale,
      );

  Future<void> expectSpoken(WidgetTester tester, String sentence) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel(sentence), findsOneWidget);
    handle.dispose();
  }

  group('PaceCard (FR-SP-3, D133)', () {
    testWidgets('worked example: the forecast key, the dates and the whole sentence', (WidgetTester tester) async {
      await pump(tester, _pace(WorkedExample.entries));
      expect(find.text('At this pace'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('pace-dates')), findsOneWidget);
      expect(find.text('₹7,042 under steady pace. At this pace about ₹9,300 spare.'), findsOneWidget);
      await expectSpoken(
        tester,
        '27,570 rupees spent so far of 45,000 rupees. Spending slower. 7,042 rupees under steady pace. '
        'At this pace about 9,300 rupees spare.',
      );
    });

    testWidgets('spending fast: over the steady line, and it runs out on 1 Nov', (WidgetTester tester) async {
      await pump(tester, _pace(_fast), spent: 36570);
      expect(find.text('Spending faster'), findsOneWidget);
      expect(find.text('₹1,958 over steady pace. At this pace it runs out on 1 Nov.'), findsOneWidget);
      await expectSpoken(
        tester,
        '36,570 rupees spent so far of 45,000 rupees. Spending faster. 1,958 rupees over steady pace. '
        'At this pace it runs out on 1 Nov.',
      );
    });

    testWidgets('rent day: too early to forecast, so no forecast key or sentence', (WidgetTester tester) async {
      await pump(tester, _pace(<Entry>[_spent(8200, _rentDay, recurringId: 2)], asOf: _rentDay), spent: 8200);
      expect(find.text('At this pace'), findsNothing);
      expect(find.text('₹2,296 under steady pace.'), findsOneWidget);
      await expectSpoken(tester, '8,200 rupees spent so far of 45,000 rupees. Spending slower. 2,296 rupees under steady pace.');
    });

    testWidgets('past the budget with nothing typed: it runs out today, drawn as one point', (WidgetTester tester) async {
      const CalendarDate today = CalendarDate(2026, 10, 9);
      await pump(tester, _pace(<Entry>[_spent(8200, _rentDay, recurringId: 2)], asOf: today, budget: 5000), spent: 8200);
      expect(tester.takeException(), isNull);
      await expectSpoken(
        tester,
        // Bills of ₹9,400 pass the ₹5,000, so the steady line is the bills alone: exactly on it.
        '8,200 rupees spent so far of 5,000 rupees. Spending slower. 0 rupees under steady pace. At this pace it runs out on 9 Oct.',
      );
    });

    testWidgets('a past cycle reads as before: no gap, no forecast, no Today', (WidgetTester tester) async {
      await pump(tester, _pace(WorkedExample.entries, asOf: _cycle.end, isCurrent: false), showToday: false);
      expect(find.text('At this pace'), findsNothing);
      expect(find.textContaining('steady pace'), findsNothing);
      await expectSpoken(tester, '27,570 rupees spent so far of 45,000 rupees. Spending slower.');
    });

    testWidgets('with no money in, only the total shows', (WidgetTester tester) async {
      await pump(tester, const Option<PaceSeries>.none());
      expect(find.byKey(const ValueKey<String>('pace-dates')), findsNothing);
      await expectSpoken(tester, 'Spent so far: 27,570 rupees');
    });

    testWidgets('the plot is 0.6 of its width, 168–216, with the date row just under it (D135)', (WidgetTester tester) async {
      await pump(tester, _pace(WorkedExample.entries));
      final Rect chart = tester.getRect(find.byKey(const ValueKey<String>('pace-chart')));
      final Rect dates = tester.getRect(find.byKey(const ValueKey<String>('pace-dates')));
      expect(chart.height, closeTo((chart.width * 0.6).clamp(168, 216), 0.01));
      expect(dates.top, chart.bottom + HisaabSpacing.xs);
      expect((dates.left, dates.right), (chart.left, chart.right));
    });

    final List<(String, Size, double)> heights = <(String, Size, double)>[
      ('a 320dp phone keeps the 168 floor', TestWindows.smallPhone, 168),
      ('a tablet stops at 216', TestWindows.tablet, 216),
      ('a phone on its side stays at 160, so the short window keeps room', TestWindows.phoneLandscape, 160),
    ];
    for (final (String name, Size size, double height) in heights) {
      testWidgets('plot height: $name (D135)', (WidgetTester tester) async {
        await pump(tester, _pace(WorkedExample.entries), size: size);
        expect(tester.getSize(find.byKey(const ValueKey<String>('pace-chart'))).height, height);
      });
    }

    testWidgets('the words on the chart follow the phone\'s text size (WCAG 1.4.4)', (WidgetTester tester) async {
      await pump(tester, _pace(WorkedExample.entries));
      final double plain = tester.getSize(find.byKey(const ValueKey<String>('pace-dates'))).height;
      await pump(tester, _pace(WorkedExample.entries), textScale: 2);
      expect(tester.getSize(find.byKey(const ValueKey<String>('pace-dates'))).height, closeTo(plain * 2, 1));
      final CustomPaint chart = tester.widget(find.descendant(of: find.byKey(const ValueKey<String>('pace-chart')), matching: find.byType(CustomPaint)));
      expect((chart.painter! as PaceChartPainter).textScaler.scale(12), 24);
    });

    final List<(String, Size, double)> windows = <(String, Size, double)>[
      ('a 320dp phone at 2× text', TestWindows.smallPhone, 2),
      ('a phone on its side at 1.5× text', TestWindows.phoneLandscape, 1.5),
      ('an unfolded foldable', TestWindows.foldableUnfolded, 1),
      ('a tablet', TestWindows.tablet, 1),
    ];
    for (final (String name, Size size, double scale) in windows) {
      testWidgets('lays out without overflow on $name, today early or late', (WidgetTester tester) async {
        await pump(tester, _pace(_fast), size: size, textScale: scale);
        expect(tester.takeException(), isNull);
        await pump(tester, _pace(<Entry>[_spent(8200, _rentDay, recurringId: 2)], asOf: _rentDay), size: size, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
