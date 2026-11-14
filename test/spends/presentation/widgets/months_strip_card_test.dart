import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/money/money_formatter.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/l10n/gen/app_localizations.dart';
import 'package:hisaab/spends/domain/entities/cycle_bar.dart';
import 'package:hisaab/spends/domain/entities/money_split.dart';
import 'package:hisaab/spends/presentation/month_story_copy.dart';
import 'package:hisaab/spends/presentation/spends_graph_copy.dart';
import 'package:hisaab/spends/presentation/widgets/month_bar_painter.dart';
import 'package:hisaab/spends/presentation/widgets/month_strip_slot.dart';
import 'package:hisaab/spends/presentation/widgets/months_strip_card.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';

Money _r(int rupees) => Money.fromMajor(rupees);

PayCycle _month(int month) => PayCycle(start: CalendarDate(2026, month, 4), end: CalendarDate(2026, month + 1, 3));

CycleBar _bar(int month, int back, {int spent = 39600, int saved = 1000, int income = 45000}) => CycleBar(
      cycle: _month(month),
      cyclesBack: back,
      split: MoneySplit(income: _r(income), bills: Money.zero, saved: _r(saved), everyday: _r(spent), notLogged: Money.zero),
      isRunning: back == 0,
      daysLeft: back == 0 ? 8 : 0,
    );

void main() {
  final MonthsStrip strip = MonthsStrip(<CycleBar>[
    _bar(4, 6, spent: 40000),
    _bar(5, 5, spent: 41200),
    _bar(6, 4, spent: 38900),
    _bar(7, 3, spent: 43600),
    _bar(8, 2, spent: 47100),
    _bar(9, 1),
    _bar(10, 0, spent: 27570),
  ]);
  late List<int> opened;

  setUp(() => opened = <int>[]);

  Future<void> pump(WidgetTester tester, {Size size = TestWindows.phone, double textScale = 1, int shown = 0}) => pumpApp(
        tester,
        Builder(
          builder: (BuildContext context) {
            final AppLocalizations strings = AppLocalizations.of(context);
            return Scaffold(
              body: ListView(
                children: <Widget>[
                  MonthsStripCard(
                    strip: strip,
                    copy: SpendsGraphCopy(
                      strings: strings,
                      shown: MonthStoryCopy.shown(MoneyFormatter()),
                      spoken: MonthStoryCopy.spoken(strings, MoneyFormatter()),
                      locale: 'en_IN',
                      today: const CalendarDate(2026, 10, 26),
                    ),
                    shownCyclesBack: shown,
                    onOpen: opened.add,
                  ),
                ],
              ),
            );
          },
        ),
        size: size,
        textScale: textScale,
      );

  group('MonthsStripCard (FR-SP-8)', () {
    testWidgets('a phone shows 5 months with the count, the key and the last finished one read out', (WidgetTester tester) async {
      await pump(tester, size: TestWindows.smallPhone);
      expect(find.byType(MonthStripSlot), findsNWidgets(5));
      expect(find.text('Last 5 months'), findsOneWidget);
      expect(find.text('Money was left over in 3 of the last 4 months.'), findsOneWidget);
      expect(find.text('Money in ₹45,000'), findsOneWidget);
      expect(find.text('Dark is spent. Outline is saved.'), findsOneWidget);
      expect(find.text('September: spent ₹39,600, saved ₹1,000. ₹4,400 left over.'), findsOneWidget);
    });

    testWidgets('a wide card shows 6', (WidgetTester tester) async {
      await pump(tester, size: TestWindows.tablet);
      expect(find.byType(MonthStripSlot), findsNWidgets(6));
    });

    testWidgets('tapping a month reads it; Open shows it', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey<int>(2)));
      await tester.pump();
      expect(find.text('August: spent ₹47,100, saved ₹1,000. ₹3,100 more than came in.'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('strip-open')));
      expect(opened, <int>[2]);
    });

    testWidgets('no Open when the picked month is the one shown', (WidgetTester tester) async {
      await pump(tester, shown: 1);
      expect(find.byKey(const ValueKey<String>('strip-open')), findsNothing);
      await tester.tap(find.byKey(const ValueKey<int>(0)));
      await tester.pump();
      expect(find.text('October so far: spent ₹27,570, saved ₹1,000. 8 days to go.'), findsOneWidget);
    });

    testWidgets('each month is a 48dp button with its sentence and selected state; the read-out is hidden', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pump(tester, size: TestWindows.smallPhone);
      expect(
        tester.getSemantics(find.byKey(const ValueKey<int>(1))),
        isSemantics(label: 'September: spent 39,600 rupees, saved 1,000 rupees. 4,400 rupees left over.', isButton: true, isSelected: true),
      );
      expect(find.bySemanticsLabel('September: spent ₹39,600, saved ₹1,000. ₹4,400 left over.'), findsNothing);
      for (final Element slot in find.byType(MonthStripSlot).evaluate()) {
        expect(tester.getSize(find.byWidget(slot.widget)).width, greaterThanOrEqualTo(48));
      }
      semantics.dispose();
    });

    testWidgets('at 1.5× text the months become rows, and hold at 2.0×', (WidgetTester tester) async {
      await pump(tester, textScale: 1.5);
      final double first = tester.getTopLeft(find.byKey(const ValueKey<int>(4))).dy;
      expect(tester.getTopLeft(find.byKey(const ValueKey<int>(3))).dy, greaterThan(first));
      await pump(tester, textScale: 2, size: TestWindows.smallPhone);
      expect(tester.takeException(), isNull);
    });
  });

  group('MonthBarPainter', () {
    const MonthBarColours colours = (ink: Color(0xFF000000), ink2: Color(0xFF777777), surface: Color(0xFFFFFFFF));

    testWidgets('paints finished, running, over, empty and horizontal bars', (WidgetTester tester) async {
      for (final (MonthBarData data, bool vertical) in <(MonthBarData, bool)>[
        ((spent: 39600, saved: 1000, income: 45000, scale: 48100, running: false), true),
        ((spent: 27570, saved: 1000, income: 45000, scale: 48100, running: true), true),
        ((spent: 47100, saved: 1000, income: 45000, scale: 48100, running: false), false),
        ((spent: 0, saved: 0, income: 0, scale: 0, running: false), true),
        ((spent: 100, saved: 0, income: 0, scale: 100, running: false), true),
      ]) {
        await tester.pumpWidget(Center(child: SizedBox(width: 60, height: 120, child: CustomPaint(painter: MonthBarPainter(data: data, colours: colours, vertical: vertical)))));
      }
      expect(tester.takeException(), isNull);
    });

    test('repaints only when its inputs change', () {
      const MonthBarPainter a = MonthBarPainter(data: (spent: 1, saved: 2, income: 3, scale: 4, running: false), colours: colours);
      expect(a.shouldRepaint(const MonthBarPainter(data: (spent: 1, saved: 2, income: 3, scale: 4, running: false), colours: colours)), isFalse);
      expect(a.shouldRepaint(const MonthBarPainter(data: (spent: 1, saved: 2, income: 3, scale: 4, running: false), colours: colours, vertical: false)), isTrue);
    });
  });
}
