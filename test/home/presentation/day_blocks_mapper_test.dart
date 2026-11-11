import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/core/widgets/day_blocks/day_blocks_data.dart';
import 'package:hisaab/home/presentation/day_blocks_mapper.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

CycleSummary _summary({required CycleState state, int share = 1850, int spent = 420, int? tomorrow = 2028}) => CycleSummary(
      cycle: const PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3)),
      today: const CalendarDate(2026, 10, 26),
      pool: Money.fromMajor(16650),
      todayShare: Money.fromMajor(share),
      spentToday: Money.fromMajor(spent),
      tomorrowShare: tomorrow == null ? const Option<Money>.none() : Option<Money>.of(Money.fromMajor(tomorrow)),
      state: state,
      forecast: const TooEarlyToForecast(),
      earliestEntryDate: const CalendarDate(2026, 9, 4),
    );

void main() {
  group('DayBlocksMapper (BR-6)', () {
    test('one block per day left; today drains with spending; later blocks cap at full height', () {
      final DayBlocksData data = DayBlocksMapper.of(_summary(state: const OnTrack()));
      expect(data.count, 9);
      expect(data.style, DayBlocksStyle.onTrack);
      expect(data.todayFill, closeTo(1430 / 1850, 1e-9));
      expect(data.laterHeight, 1);
    });

    test('overspending empties today and shortens later blocks, but not below 40%', () {
      final DayBlocksData shorter = DayBlocksMapper.of(_summary(state: OverToday(Money.fromMajor(1020)), spent: 2870, tomorrow: 1722));
      expect(shorter.todayFill, 0);
      expect(shorter.laterHeight, closeTo(1722 / 1850, 1e-9));
      expect(DayBlocksMapper.of(_summary(state: OverToday(Money.fromMajor(1)), tomorrow: 100)).laterHeight, 0.4);
    });

    test('any spend shows: once something is spent, today is at most 90% full (D91)', () {
      // BR-6 worked example: ₹700 of ₹11,218 is 94% left, drawn as 90%.
      expect(DayBlocksMapper.of(_summary(state: const OnTrack(), share: 11218, spent: 700)).todayFill, 0.9);
      expect(DayBlocksMapper.of(_summary(state: const OnTrack(), share: 11218, spent: 0)).todayFill, 1);
      expect(DayBlocksMapper.of(_summary(state: const OnTrack(), share: 11218, spent: 1)).todayFill, 0.9);
      expect(DayBlocksMapper.of(_summary(state: const OnTrack(), share: 1850, spent: 1000)).todayFill, closeTo(850 / 1850, 1e-9));
    });

    test('A = 0 gives an empty today and full-height later blocks', () {
      final DayBlocksData data = DayBlocksMapper.of(_summary(state: const SlowDown(), share: 0, spent: 0));
      expect((data.todayFill, data.laterHeight), (0.0, 1.0));
    });

    test('the last day has no later share', () {
      expect(DayBlocksMapper.of(_summary(state: const OnTrack(), tomorrow: null)).laterHeight, 1);
    });

    final List<(CycleState, DayBlocksStyle)> styles = <(CycleState, DayBlocksStyle)>[
      (const SlowDown(), DayBlocksStyle.slowDown),
      (OverCycle(Money.fromMajor(1)), DayBlocksStyle.overCycle),
      (const NoIncome(), DayBlocksStyle.overCycle),
    ];
    for (final (CycleState state, DayBlocksStyle style) in styles) {
      test('$state draws as ${style.name}', () => expect(DayBlocksMapper.of(_summary(state: state)).style, style));
    }
  });
}
