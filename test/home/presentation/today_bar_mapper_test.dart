import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/core/widgets/today_bar/today_bar_data.dart';
import 'package:expense_tracker/home/presentation/today_bar_mapper.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

const CalendarDate _today = CalendarDate(2026, 10, 29);

CycleSummary _summary({CycleState state = const OnTrack(), int share = 1850, int spent = 420}) => CycleSummary(
      cycle: const PayCycle(start: CalendarDate(2026, 10, 7), end: CalendarDate(2026, 11, 6)),
      today: _today,
      pool: Money.fromMajor(16650),
      todayShare: Money.fromMajor(share),
      spentToday: Money.fromMajor(spent),
      tomorrowShare: const Option<Money>.none(),
      state: state,
      forecast: const TooEarlyToForecast(),
      earliestEntryDate: const CalendarDate(2026, 9, 7),
    );

Entry _spend(int id, int rupees, {int category = 1}) => Entry(
      id: id,
      amount: Money.fromMajor(rupees),
      kind: EntryKind.spent,
      categoryId: category,
      date: _today,
      createdAt: DateTime(2026, 10, 29, 8 + id),
    );

String _name(Entry entry) => 'category ${entry.categoryId}';

void main() {
  group('TodayBarMapper (BR-6)', () {
    test('worked example: the yellow is what is left; chai and lunch are bites, in the order saved', () {
      final TodayBarData data = TodayBarMapper.of(
        _summary(),
        <Entry>[_spend(1, 40, category: 7), _spend(2, 380, category: 3)],
        nameOf: _name,
      );
      expect(data.style, TodayBarStyle.onTrack);
      expect(data.left, closeTo(1430 / 1850, 1e-9));
      expect(data.bites.map((TodayBite b) => b.share), <Matcher>[closeTo(40 / 1850, 1e-9), closeTo(380 / 1850, 1e-9)]);
      expect(data.bites.map((TodayBite b) => b.label), <String>['category 7', 'category 3']);
      expect(data.tick, isNull);
    });

    test('nothing spent: the yellow is the whole bar, with no bites', () {
      final TodayBarData data = TodayBarMapper.of(_summary(spent: 0), const <Entry>[], nameOf: _name);
      expect(data.left, 1);
      expect(data.bites, isEmpty);
      expect(data.tick, isNull);
    });

    test('spending exactly today\'s share leaves no yellow and no hatch (a day at its share is within it)', () {
      final TodayBarData data = TodayBarMapper.of(_summary(spent: 1850), <Entry>[_spend(1, 1850)], nameOf: _name);
      expect(data.left, 0);
      expect(data.bites.single.share, 1);
      expect(data.tick, isNull);
    });

    test('over today: the bar spans what was spent, with the tick at today\'s share', () {
      final TodayBarData data = TodayBarMapper.of(
        _summary(state: OverToday(Money.fromMajor(450)), spent: 2300),
        <Entry>[_spend(1, 40), _spend(2, 380), _spend(3, 1080), _spend(4, 800)],
        nameOf: _name,
      );
      expect(data.style, TodayBarStyle.over);
      expect(data.left, 0);
      expect(data.tick, closeTo(1850 / 2300, 1e-9));
      expect(data.bites.fold(0.0, (double sum, TodayBite b) => sum + b.share), closeTo(1, 1e-9));
    });

    test('overspend larger than the whole share still fits the bar', () {
      final TodayBarData data = TodayBarMapper.of(
        _summary(state: OverCycle(Money.fromMajor(5000)), spent: 20000),
        <Entry>[_spend(1, 20000)],
        nameOf: _name,
      );
      expect(data.style, TodayBarStyle.over);
      expect(data.tick, closeTo(1850 / 20000, 1e-9));
      expect(data.bites.single.share, 1);
    });

    test('A = 0 and nothing spent: an empty bar', () {
      final TodayBarData data = TodayBarMapper.of(_summary(share: 0, spent: 0), const <Entry>[], nameOf: _name);
      expect(data.left, 0);
      expect(data.bites, isEmpty);
      expect(data.tick, isNull);
    });

    test('A = 0 with a spend: everything is past the share', () {
      final TodayBarData data = TodayBarMapper.of(
        _summary(state: OverCycle(Money.fromMajor(100)), share: 0, spent: 100),
        <Entry>[_spend(1, 100)],
        nameOf: _name,
      );
      expect((data.left, data.tick, data.bites.single.share), (0.0, 0.0, 1.0));
    });

    final List<(CycleState, TodayBarStyle)> styles = <(CycleState, TodayBarStyle)>[
      (const OnTrack(), TodayBarStyle.onTrack),
      (const SlowDown(), TodayBarStyle.slowDown),
      (OverToday(Money.fromMajor(1)), TodayBarStyle.over),
      (OverCycle(Money.fromMajor(1)), TodayBarStyle.over),
      (const NoIncome(), TodayBarStyle.over),
    ];
    for (final (CycleState state, TodayBarStyle style) in styles) {
      test('${state.runtimeType} draws as $style', () {
        expect(TodayBarMapper.of(_summary(state: state), const <Entry>[], nameOf: _name).style, style);
      });
    }
  });
}
