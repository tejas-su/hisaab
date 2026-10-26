import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/money/money_formatter.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/home/presentation/hero_copy.dart';
import 'package:expense_tracker/l10n/gen/app_localizations.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/date_symbol_data_local.dart';

final AppLocalizations _strings = lookupAppLocalizations(const Locale('en'));
final MoneyFormatter _money = MoneyFormatter();

CycleSummary _summary({
  required CycleState state,
  RangeForecast forecast = const TooEarlyToForecast(),
  int share = 1850,
  int spentToday = 420,
  Option<Money> tomorrow = const Option<Money>.none(),
  CalendarDate today = const CalendarDate(2026, 10, 26),
}) =>
    CycleSummary(
      cycle: const PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3)),
      today: today,
      pool: Money.fromMajor(16650),
      todayShare: Money.fromMajor(share),
      spentToday: Money.fromMajor(spentToday),
      tomorrowShare: tomorrow,
      state: state,
      forecast: forecast,
      earliestEntryDate: const CalendarDate(2026, 9, 4),
    );

HeroCopy _copy(CycleSummary summary) => HeroCopy.of(summary, strings: _strings, money: _money);

void main() {
  setUpAll(() => initializeDateFormatting('en_IN'));

  group('HeroCopy (BR-5, BR-7, FR-HO-7)', () {
    test('on track: amount, payday flag, spare forecast and one spoken sentence', () {
      final HeroCopy copy = _copy(_summary(state: const OnTrack(), forecast: LastsTillPayday(Money.fromMajor(9300))));
      expect(copy.heroAmount, Money.fromMajor(1430));
      expect(copy.muted, isFalse);
      expect(copy.overText, const Option<String>.none());
      expect(copy.payday, '4 Nov');
      expect(copy.laterCaption, '9 days to payday');
      expect(copy.range, const RangeWords('Lasts till payday', 'about ₹9,300 spare'));
      expect(copy.calm, isTrue);
      expect(
        copy.spoken,
        'Safe to spend today: 1,430 rupees. 9 days to payday. Lasts till payday, about 9,300 rupees spare.',
      );
    });

    test('too early to forecast just says it lasts', () {
      final HeroCopy copy = _copy(_summary(state: const OnTrack()));
      expect(copy.range, const RangeWords('Lasts till payday'));
      expect(copy.spoken, endsWith('Lasts till payday.'));
    });

    test('a forecast that runs out is never calm', () {
      final HeroCopy copy = _copy(_summary(state: const OnTrack(), forecast: const RunsOut(CalendarDate(2026, 11, 22))));
      expect(copy.range, const RangeWords('At this pace it runs out on 22 Nov'));
      expect(copy.calm, isFalse);
    });

    test('slow down names the run-out date when there is one', () {
      expect(
        _copy(_summary(state: const SlowDown(), forecast: const RunsOut(CalendarDate(2026, 10, 29)))).range,
        const RangeWords('Slow down', 'at this pace it runs out on 29 Oct'),
      );
      expect(_copy(_summary(state: const SlowDown())).range, const RangeWords('Slow down', "today's share is almost used"));
    });

    test('over today: ₹0, muted, the overspend beside it and each later day\'s share', () {
      final HeroCopy copy = _copy(
        _summary(
          state: OverToday(Money.fromMajor(220)),
          spentToday: 2070,
          tomorrow: Option<Money>.of(Money.fromMajor(1776)),
          forecast: LastsTillPayday(Money.fromMajor(400)),
        ),
      );
      expect(copy.heroAmount, Money.zero);
      expect(copy.muted, isTrue);
      expect(copy.overText, const Option<String>.of('₹220 over today'));
      expect(copy.laterCaption, 'Each day after: ₹1,776');
      expect(copy.range, const RangeWords('Over today', 'still lasts till payday'));
      expect(copy.spoken, contains('Each day after: 1,776 rupees'));
    });

    test('over today on the last day falls back to days to payday', () {
      final HeroCopy copy = _copy(_summary(state: OverToday(Money.fromMajor(5)), today: const CalendarDate(2026, 11, 3)));
      expect(copy.laterCaption, '1 day to payday');
    });

    test('over today with a run-out forecast says so', () {
      expect(
        _copy(_summary(state: OverToday(Money.fromMajor(5)), forecast: const RunsOut(CalendarDate(2026, 10, 30)))).range.detail,
        'at this pace it runs out on 30 Oct',
      );
    });

    test('over for the cycle: ₹0 and the shortfall, with days to payday', () {
      final HeroCopy copy = _copy(_summary(state: OverCycle(Money.fromMajor(1200)), spentToday: 99999));
      expect(copy.heroAmount, Money.zero);
      expect(copy.overText, const Option<String>.of('₹1,200 over'));
      expect(copy.range, const RangeWords('Over by ₹1,200', 'payday in 9 days'));
      expect(_copy(_summary(state: OverCycle(Money.fromMajor(1)), today: const CalendarDate(2026, 11, 3))).range.detail, 'payday tomorrow');
    });

    test('never shows a negative hero', () {
      expect(_copy(_summary(state: const SlowDown(), share: 0, spentToday: 0)).heroAmount, Money.zero);
      expect(_copy(_summary(state: const NoIncome(), share: 100, spentToday: 400)).heroAmount, Money.zero);
    });

    test('compares by value', () {
      expect(_copy(_summary(state: const OnTrack())), _copy(_summary(state: const OnTrack())));
    });
  });
}
