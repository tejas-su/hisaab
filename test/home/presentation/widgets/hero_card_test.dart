import 'package:expense_tracker/core/design/hisaab_colors.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/core/widgets/display_card.dart';
import 'package:expense_tracker/core/widgets/amount_text.dart';
import 'package:expense_tracker/core/widgets/day_blocks/day_blocks.dart';
import 'package:expense_tracker/core/widgets/display_etch.dart';
import 'package:expense_tracker/core/widgets/week_bars/week_bars.dart';
import 'package:expense_tracker/core/widgets/week_bars/week_letters.dart';
import 'package:expense_tracker/home/presentation/widgets/hero_card.dart';
import 'package:expense_tracker/home/presentation/widgets/hero_press.dart';
import 'package:expense_tracker/home/presentation/widgets/hero_sheen.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Option;

import '../../../helpers/pump_app.dart';

CycleSummary _summary(CalendarDate today) => CycleSummary(
  cycle: const PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3)),
  today: today,
  pool: Money.fromMajor(16650),
  todayShare: Money.fromMajor(1850),
  spentToday: Money.fromMajor(420),
  tomorrowShare: const Option<Money>.none(),
  state: const OnTrack(),
  forecast: LastsTillPayday(Money.fromMajor(9300)),
  earliestEntryDate: const CalendarDate(2026, 9, 4),
  spentThisWeek: Money.fromMajor(420),
);

void main() {
  group('HeroCard material (D106, case study 10)', () {
    testWidgets('is the raised, etched card, pressed as one card, with the sheen over it', (WidgetTester tester) async {
      int taps = 0;
      await pumpApp(tester, HeroCard(summary: _summary(const CalendarDate(2026, 10, 26)), onTap: () => taps++));
      final DisplayCard card = tester.widget<DisplayCard>(find.byType(DisplayCard));
      expect(card.raised, isTrue);
      expect(card.etched, isTrue);
      expect(find.byType(DisplayEtch), findsOneWidget);
      expect(find.ancestor(of: find.byType(DisplayCard), matching: find.byType(HeroSheen)), findsOneWidget);
      expect(find.ancestor(of: find.byType(HeroSheen), matching: find.byType(HeroPress)), findsOneWidget);
      await tester.tap(find.byType(HeroCard));
      expect(taps, 1);
    });

    testWidgets('breathes: roomy gaps between the label, amount, blocks and range line, and a quiet divider (D107)', (
      WidgetTester tester,
    ) async {
      await pumpApp(tester, HeroCard(summary: _summary(const CalendarDate(2026, 10, 26)), onTap: () {}));
      double top(Finder f) => tester.getRect(f).top;
      double bottom(Finder f) => tester.getRect(f).bottom;
      final Finder blocks = find.byType(DayBlocks);
      final Finder divider = find.descendant(of: find.byType(HeroCard), matching: find.byType(Divider));
      expect(top(blocks) - bottom(find.textContaining('₹1,430')), greaterThanOrEqualTo(24));
      expect(top(divider) - bottom(find.text('9 days to payday')), 20);
      expect(top(find.textContaining('Lasts till payday')) - bottom(divider), greaterThanOrEqualTo(16));
      expect(tester.widget<Divider>(divider).color, HisaabColors.light.displayEtch);
    });

    testWidgets('the amount rolls on its own layer, so the card does not repaint with it', (WidgetTester tester) async {
      await pumpApp(tester, HeroCard(summary: _summary(const CalendarDate(2026, 10, 26)), onTap: () {}));
      final Finder amount = find.byType(AmountText);
      expect(find.ancestor(of: amount, matching: find.byType(RepaintBoundary)).evaluate().first.widget, isA<RepaintBoundary>());
      expect(
        tester
            .element(find.ancestor(of: amount, matching: find.byType(RepaintBoundary)).first)
            .findAncestorWidgetOfExactType<DisplayCard>(),
        isNotNull,
        reason: 'the boundary sits inside the card, around the amount alone',
      );
    });

    testWidgets('a new day gives the sheen a new key, so it plays again', (WidgetTester tester) async {
      await pumpApp(tester, HeroCard(summary: _summary(const CalendarDate(2026, 10, 26)), onTap: () {}));
      final Key? first = tester.widget<HeroSheen>(find.byType(HeroSheen)).key;
      await pumpApp(tester, HeroCard(summary: _summary(const CalendarDate(2026, 10, 27)), onTap: () {}));
      expect(tester.widget<HeroSheen>(find.byType(HeroSheen)).key, isNot(first));
    });
  });

  group('HeroCard — This week (FR-HO-2, BR-6a, case study 15 W2)', () {
    CycleSummary thursday() => CycleSummary(
          cycle: const PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3)),
          today: const CalendarDate(2026, 10, 29),
          pool: Money.fromMajor(11100),
          todayShare: Money.fromMajor(1850),
          spentToday: Money.fromMajor(420),
          tomorrowShare: const Option<Money>.none(),
          state: const OnTrack(),
          forecast: LastsTillPayday(Money.fromMajor(9300)),
          earliestEntryDate: const CalendarDate(2026, 9, 4),
          spentThisWeek: Money.fromMajor(4950),
          week: <WeekDay>[
            WeekDay(date: const CalendarDate(2026, 10, 26), spent: Money.fromMajor(1240), share: Money.fromMajor(1820)),
            WeekDay(date: const CalendarDate(2026, 10, 27), spent: Money.fromMajor(2310), share: Money.fromMajor(1850)),
            WeekDay(date: const CalendarDate(2026, 10, 28), spent: Money.fromMajor(980), share: Money.fromMajor(1790)),
            WeekDay(date: const CalendarDate(2026, 10, 29), spent: Money.fromMajor(420), share: Money.fromMajor(1850)),
          ],
        );

    testWidgets('the weekday bars and letters take the blocks\' and captions\' place; the flag stays', (WidgetTester tester) async {
      await pumpApp(tester, HeroCard(summary: thursday(), onTap: () {}, week: true));
      expect(find.byType(WeekBars), findsOneWidget);
      expect(find.byType(WeekLetters), findsOneWidget);
      expect(find.byType(DayBlocks), findsNothing);
      expect(find.text('9 days to payday'), findsNothing);
      expect(find.text('4 Nov'), findsOneWidget);
      expect(find.textContaining('Tue was ₹460 over its share'), findsOneWidget);
    });

    testWidgets('the card grows by 48dp for the bars, only in This week', (WidgetTester tester) async {
      // why: on Home the hero sits in a scrolling column, so it takes its own height.
      Widget atTop({bool week = false}) =>
          SingleChildScrollView(child: HeroCard(summary: thursday(), onTap: () {}, week: week));
      await pumpApp(tester, atTop());
      final double today = tester.getSize(find.byType(DisplayCard)).height;
      await pumpApp(tester, atTop(week: true));
      final double week = tester.getSize(find.byType(DisplayCard)).height;
      await pumpApp(tester, atTop());
      expect(week - today, 48);
      expect(tester.getSize(find.byType(DisplayCard)).height, today, reason: 'flipping back gives the room back');
    });

    testWidgets('the bars are 88dp tall and share the blocks\' left and right edges', (WidgetTester tester) async {
      await pumpApp(tester, HeroCard(summary: thursday(), onTap: () {}));
      final Rect blocks = tester.getRect(find.byType(DayBlocks));
      await pumpApp(tester, HeroCard(summary: thursday(), onTap: () {}, week: true));
      final Rect bars = tester.getRect(find.byType(WeekBars));
      expect(bars.height, 88);
      expect(bars.left, blocks.left);
      expect(bars.right, blocks.right);
      expect(tester.getRect(find.byType(WeekLetters)).width, bars.width);
    });

    testWidgets('with reduced motion the card changes size at once', (WidgetTester tester) async {
      await pumpApp(tester, HeroCard(summary: thursday(), onTap: () {}), reduceMotion: true);
      await pumpApp(tester, HeroCard(summary: thursday(), onTap: () {}, week: true), reduceMotion: true, settle: false);
      expect(find.byType(AnimatedSize), findsNothing);
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(WeekBars), findsOneWidget);
    });

    testWidgets('it holds at 1.5× text on a small phone', (WidgetTester tester) async {
      await pumpApp(tester, HeroCard(summary: thursday(), onTap: () {}, week: true), textScale: 1.5, size: const Size(320, 568));
      expect(tester.takeException(), isNull);
    });
  });
}
