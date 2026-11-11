import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/core/widgets/week_bars/week_bars_data.dart';
import 'package:hisaab/home/presentation/week_bars_mapper.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/date_symbol_data_local.dart';

WeekDay _day(int october, int spent, {int share = 1850}) =>
    WeekDay(date: CalendarDate(2026, 10, october), spent: Money.fromMajor(spent), share: Money.fromMajor(share));

CycleSummary _summary({
  required CalendarDate today,
  required List<WeekDay> week,
  PayCycle cycle = const PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3)),
}) =>
    CycleSummary(
      cycle: cycle,
      today: today,
      pool: Money.fromMajor(16650),
      todayShare: Money.fromMajor(1850),
      spentToday: week.last.spent,
      tomorrowShare: const Option<Money>.none(),
      state: const OnTrack(),
      forecast: const TooEarlyToForecast(),
      earliestEntryDate: const CalendarDate(2026, 9, 4),
      week: week,
    );

List<WeekBarKind> _kinds(WeekBarsData data) => data.bars.map((WeekBar bar) => bar.kind).toList();

void main() {
  setUpAll(() => initializeDateFormatting('en_IN'));

  group('WeekBarsMapper (BR-6a)', () {
    test('Thursday: three past days, today, and three days to come', () {
      final WeekBarsData data = WeekBarsMapper.of(_summary(
        today: const CalendarDate(2026, 10, 29),
        week: <WeekDay>[_day(26, 1240, share: 1820), _day(27, 2310), _day(28, 980, share: 1790), _day(29, 420)],
      ));
      expect(_kinds(data), <WeekBarKind>[
        WeekBarKind.past,
        WeekBarKind.past,
        WeekBarKind.past,
        WeekBarKind.today,
        WeekBarKind.future,
        WeekBarKind.future,
        WeekBarKind.future,
      ]);
      expect(data.todayIndex, 3);
    });

    test('heights are shares of the tallest value, so Tuesday\'s spend is full height', () {
      final WeekBarsData data = WeekBarsMapper.of(_summary(
        today: const CalendarDate(2026, 10, 29),
        week: <WeekDay>[_day(26, 1240, share: 1820), _day(27, 2310), _day(28, 980, share: 1790), _day(29, 420)],
      ));
      expect(data.bars[1].spent, 1);
      expect(data.bars[1].share, closeTo(1850 / 2310, 1e-9));
      expect(data.bars[1].isOver, isTrue);
      expect(data.bars[0].isOver, isFalse);
    });

    test('a share taller than any spend sets the scale', () {
      final WeekBarsData data = WeekBarsMapper.of(_summary(today: const CalendarDate(2026, 10, 26), week: <WeekDay>[_day(26, 420)]));
      expect(data.bars[0].share, 1);
      expect(data.bars[0].spent, closeTo(420 / 1850, 1e-9));
    });

    test('a week with nothing spent and ₹0 shares draws flat, never dividing by zero', () {
      final WeekBarsData data = WeekBarsMapper.of(_summary(
        today: const CalendarDate(2026, 10, 27),
        week: <WeekDay>[_day(26, 0, share: 0), _day(27, 0, share: 0)],
      ));
      expect(data.bars.take(2).map((WeekBar bar) => (bar.spent, bar.share)), <(double, double)>[(0, 0), (0, 0)]);
    });

    test('days before the cycle started draw nothing', () {
      final WeekBarsData data = WeekBarsMapper.of(_summary(
        today: const CalendarDate(2026, 10, 29),
        cycle: const PayCycle(start: CalendarDate(2026, 10, 28), end: CalendarDate(2026, 11, 27)),
        week: <WeekDay>[_day(28, 300), _day(29, 420)],
      ));
      expect(_kinds(data).take(3), <WeekBarKind>[WeekBarKind.none, WeekBarKind.none, WeekBarKind.past]);
    });

    test('from payday on, the days belong to the next cycle and draw nothing', () {
      final WeekBarsData data = WeekBarsMapper.of(_summary(
        today: const CalendarDate(2026, 10, 29),
        cycle: const PayCycle(start: CalendarDate(2026, 10, 1), end: CalendarDate(2026, 10, 30)),
        week: <WeekDay>[_day(26, 100), _day(27, 100), _day(28, 100), _day(29, 100)],
      ));
      expect(_kinds(data).skip(4), <WeekBarKind>[WeekBarKind.future, WeekBarKind.none, WeekBarKind.none]);
    });

    test('Sunday is today: no days to come', () {
      final WeekBarsData data = WeekBarsMapper.of(_summary(
        today: const CalendarDate(2026, 11, 1),
        week: <WeekDay>[for (int d = 26; d <= 31; d++) _day(d, 100), WeekDay(date: const CalendarDate(2026, 11, 1), spent: Money.fromMajor(100), share: Money.fromMajor(1850))],
      ));
      expect(data.todayIndex, 6);
      expect(_kinds(data).last, WeekBarKind.today);
    });

    test('letters are the locale\'s narrow weekday names, Monday first', () {
      expect(WeekBarsMapper.letters('en_IN'), <String>['M', 'T', 'W', 'T', 'F', 'S', 'S']);
    });
  });
}
