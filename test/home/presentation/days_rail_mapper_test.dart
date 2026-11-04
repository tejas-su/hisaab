import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/core/widgets/days_rail/days_rail_data.dart';
import 'package:expense_tracker/home/presentation/days_rail_mapper.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

CycleSummary _summary({required CalendarDate today, PayCycle? cycle, CycleState state = const OnTrack()}) => CycleSummary(
      cycle: cycle ?? const PayCycle(start: CalendarDate(2026, 10, 7), end: CalendarDate(2026, 11, 6)),
      today: today,
      pool: Money.fromMajor(16650),
      todayShare: Money.fromMajor(1850),
      spentToday: Money.fromMajor(420),
      tomorrowShare: const Option<Money>.none(),
      state: state,
      forecast: const TooEarlyToForecast(),
      earliestEntryDate: const CalendarDate(2026, 9, 7),
    );

void main() {
  group('DaysRailMapper (BR-6)', () {
    final List<(String, CycleSummary, int)> counts = <(String, CycleSummary, int)>[
      ('the worked example, Thu 29 Oct to payday Sat 7 Nov', _summary(today: const CalendarDate(2026, 10, 29)), 9),
      ('the cycle\'s first day', _summary(today: const CalendarDate(2026, 10, 7)), 31),
      ('the cycle\'s last day', _summary(today: const CalendarDate(2026, 11, 6)), 1),
      (
        'a cycle that crosses the year',
        _summary(
          today: const CalendarDate(2026, 12, 30),
          cycle: const PayCycle(start: CalendarDate(2026, 12, 29), end: CalendarDate(2027, 1, 28)),
        ),
        30,
      ),
      (
        'payday on the 29th in a leap February',
        _summary(
          today: const CalendarDate(2028, 2, 27),
          cycle: const PayCycle(start: CalendarDate(2028, 1, 29), end: CalendarDate(2028, 2, 28)),
        ),
        2,
      ),
    ];
    for (final (String name, CycleSummary summary, int count) in counts) {
      test('one dot per day left: $name', () {
        expect(DaysRailMapper.of(summary).count, count);
      });
    }

    final List<(CycleState, DaysRailStyle)> styles = <(CycleState, DaysRailStyle)>[
      (const OnTrack(), DaysRailStyle.onTrack),
      (const SlowDown(), DaysRailStyle.slowDown),
      (OverToday(Money.fromMajor(1)), DaysRailStyle.overToday),
      (OverCycle(Money.fromMajor(1)), DaysRailStyle.overCycle),
      (const NoIncome(), DaysRailStyle.overCycle),
    ];
    for (final (CycleState state, DaysRailStyle style) in styles) {
      test('${state.runtimeType} draws today\'s dot as $style', () {
        expect(DaysRailMapper.of(_summary(today: const CalendarDate(2026, 10, 29), state: state)).style, style);
      });
    }
  });
}
