import 'package:expense_tracker/core/design/hisaab_colors.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/core/widgets/display_card.dart';
import 'package:expense_tracker/core/widgets/amount_text.dart';
import 'package:expense_tracker/core/widgets/day_blocks/day_blocks.dart';
import 'package:expense_tracker/core/widgets/display_etch.dart';
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
}
