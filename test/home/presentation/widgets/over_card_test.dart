import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/home/presentation/widgets/over_card.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Option;

import '../../../helpers/pump_app.dart';

CycleSummary _overCycle(PayCycle cycle, {bool endsAtMonthEnd = false}) => CycleSummary(
      cycle: cycle,
      today: const CalendarDate(2026, 10, 26),
      pool: Money.fromMajor(1000),
      todayShare: Money.zero,
      spentToday: Money.fromMajor(3000),
      tomorrowShare: const Option<Money>.none(),
      state: OverCycle(Money.fromMajor(2000)),
      forecast: const TooEarlyToForecast(),
      earliestEntryDate: const CalendarDate(2026, 9, 1),
      endsAtMonthEnd: endsAtMonthEnd,
    );

void main() {
  group('OverCard — over for the cycle names how the cycle ends (FR-HO-5, D116)', () {
    testWidgets('a monthly payday cycle starts again on payday', (WidgetTester tester) async {
      await pumpApp(
        tester,
        OverCard(
          summary: _overCycle(const PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3))),
          onSeeWhereItWent: null,
        ),
      );
      expect(find.text("It happens. This month's money is used up. It starts again on payday, 4 Nov."), findsOneWidget);
    });

    testWidgets('a calendar-month cycle starts again on the 1st, without "payday"', (WidgetTester tester) async {
      await pumpApp(
        tester,
        OverCard(
          summary: _overCycle(
            const PayCycle(start: CalendarDate(2026, 10, 1), end: CalendarDate(2026, 10, 31)),
            endsAtMonthEnd: true,
          ),
          onSeeWhereItWent: null,
        ),
      );
      expect(find.text("It happens. This month's money is used up. It starts again on 1 Nov."), findsOneWidget);
    });

    testWidgets('a weekly cycle says this week, not this month', (WidgetTester tester) async {
      await pumpApp(
        tester,
        OverCard(
          summary: _overCycle(const PayCycle(start: CalendarDate(2026, 10, 23), end: CalendarDate(2026, 10, 29))),
          onSeeWhereItWent: null,
        ),
      );
      expect(find.text("It happens. This week's money is used up. It starts again on payday, 30 Oct."), findsOneWidget);
    });
  });
}
