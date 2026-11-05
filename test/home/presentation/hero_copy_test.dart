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
  int spentThisWeek = 420,
  List<WeekDay> week = const <WeekDay>[],
  PayCycle cycle = const PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3)),
  bool endsAtMonthEnd = false,
}) =>
    CycleSummary(
      cycle: cycle,
      today: today,
      pool: Money.fromMajor(16650),
      todayShare: Money.fromMajor(share),
      spentToday: Money.fromMajor(spentToday),
      tomorrowShare: tomorrow,
      state: state,
      forecast: forecast,
      earliestEntryDate: const CalendarDate(2026, 9, 4),
      spentThisWeek: Money.fromMajor(spentThisWeek),
      week: week,
      endsAtMonthEnd: endsAtMonthEnd,
    );

/// A calendar-month cycle ("It changes", or month start on the 1st): Mon 26 Oct is 6 days from the end.
CycleSummary _monthEnd({
  required CycleState state,
  RangeForecast forecast = const TooEarlyToForecast(),
  CalendarDate today = const CalendarDate(2026, 10, 26),
  Option<Money> tomorrow = const Option<Money>.none(),
}) =>
    _summary(
      state: state,
      forecast: forecast,
      today: today,
      tomorrow: tomorrow,
      cycle: const PayCycle(start: CalendarDate(2026, 10, 1), end: CalendarDate(2026, 10, 31)),
      endsAtMonthEnd: true,
    );

WeekDay _day(int october, {required int spent, int share = 1850}) =>
    WeekDay(date: CalendarDate(2026, 10, october), spent: Money.fromMajor(spent), share: Money.fromMajor(share));

HeroCopy _copy(CycleSummary summary) => HeroCopy.of(summary, strings: _strings, money: _money);

HeroCopy _weekCopy(CycleSummary summary) => HeroCopy.of(summary, strings: _strings, money: _money, week: true);

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
      expect(copy.laterCaption, 'From tomorrow: ₹1,776 a day');
      expect(copy.range, const RangeWords('Over today', 'still lasts till payday'));
      expect(copy.spoken, contains('From tomorrow: 1,776 rupees a day'));
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

  group('HeroCopy — month-end cycles have no payday (D116)', () {
    test('on track: days left this month and lasts till month end, shown and spoken', () {
      final HeroCopy copy = _copy(_monthEnd(state: const OnTrack(), forecast: LastsTillPayday(Money.fromMajor(9300))));
      expect(copy.laterCaption, '6 days left this month');
      expect(copy.range, const RangeWords('Lasts till month end', 'about ₹9,300 spare'));
      expect(copy.payday, '1 Nov');
      expect(
        copy.spoken,
        'Safe to spend today: 1,430 rupees. 6 days left this month. Lasts till month end, about 9,300 rupees spare.',
      );
    });

    test('too early to forecast just says it lasts till month end', () {
      expect(_copy(_monthEnd(state: const OnTrack())).range, const RangeWords('Lasts till month end'));
    });

    test('the last day of the month says so', () {
      final HeroCopy copy = _copy(_monthEnd(state: OverToday(Money.fromMajor(5)), today: const CalendarDate(2026, 10, 31)));
      expect(copy.laterCaption, 'Last day of the month');
    });

    test('over today still lasts till month end', () {
      final HeroCopy copy = _copy(_monthEnd(state: OverToday(Money.fromMajor(220)), tomorrow: Option<Money>.of(Money.fromMajor(1776))));
      expect(copy.range, const RangeWords('Over today', 'still lasts till month end'));
    });

    test('over for the cycle counts down to the new month', () {
      expect(_copy(_monthEnd(state: OverCycle(Money.fromMajor(2000)))).range, const RangeWords('Over by ₹2,000', 'new month in 6 days'));
      expect(
        _copy(_monthEnd(state: OverCycle(Money.fromMajor(1)), today: const CalendarDate(2026, 10, 31))).range.detail,
        'new month tomorrow',
      );
    });
  });

  group('HeroCopy — This week (FR-HO-2)', () {
    test('Today is the default title', () {
      expect(_copy(_summary(state: const OnTrack())).title, 'Safe to spend today');
    });

    test('on track: 7 × ₹1,850 − ₹420 = ₹12,530 this week, read aloud with the week title', () {
      final HeroCopy copy = _weekCopy(_summary(
        state: const OnTrack(),
        forecast: LastsTillPayday(Money.fromMajor(9300)),
        week: <WeekDay>[_day(26, spent: 420)],
      ));
      expect(copy.title, 'Safe to spend this week');
      expect(copy.heroAmount, Money.fromMajor(12530));
      expect(copy.muted, isFalse);
      expect(copy.overText, const Option<String>.none());
      expect(copy.range, const RangeWords('Spent ₹420 this week', 'every day within its share'));
      expect(
        copy.spoken,
        'Safe to spend this week: 12,530 rupees. Today, 420 rupees so far. Spent 420 rupees this week, every day within its share.',
      );
    });

    test('over today but not over the week: the week amount shows, without today\'s overspend', () {
      final HeroCopy copy =
          _weekCopy(_summary(state: OverToday(Money.fromMajor(220)), spentToday: 2070, spentThisWeek: 2070));
      expect(copy.heroAmount, Money.fromMajor(10880));
      expect(copy.muted, isFalse);
      expect(copy.overText, const Option<String>.none());
    });

    test('over the week: ₹0, muted, and how far over in words', () {
      final HeroCopy copy = _weekCopy(_summary(state: const OnTrack(), spentThisWeek: 13000));
      expect(copy.heroAmount, Money.zero);
      expect(copy.muted, isTrue);
      expect(copy.overText, const Option<String>.of('₹50 over this week'));
    });

    test('spending exactly the week\'s shares is ₹0 and muted, with no overspend', () {
      final HeroCopy copy = _weekCopy(_summary(state: const OnTrack(), spentThisWeek: 12950));
      expect(copy.heroAmount, Money.zero);
      expect(copy.muted, isTrue);
      expect(copy.overText, const Option<String>.none());
    });
  });

  group('HeroCopy — This week in words (BR-6a)', () {
    // Thu 29 Oct: Mon to Wed as they stood, and today.
    CycleSummary thursday(List<WeekDay> week, {int spentThisWeek = 4950}) =>
        _summary(state: const OnTrack(), today: const CalendarDate(2026, 10, 29), spentThisWeek: spentThisWeek, week: week);

    test('one day over its share: the sentence names it, and the glyph is the alert', () {
      final HeroCopy copy = _weekCopy(thursday(<WeekDay>[
        _day(26, spent: 1240, share: 1820),
        _day(27, spent: 2310),
        _day(28, spent: 980, share: 1790),
        _day(29, spent: 420),
      ]));
      expect(copy.range, const RangeWords('Spent ₹4,950 this week', 'Tue was ₹460 over its share'));
      expect(copy.calm, isFalse);
    });

    test('every day within its share: the check glyph', () {
      final HeroCopy copy = _weekCopy(thursday(<WeekDay>[_day(26, spent: 1240), _day(29, spent: 420)], spentThisWeek: 1660));
      expect(copy.range, const RangeWords('Spent ₹1,660 this week', 'every day within its share'));
      expect(copy.calm, isTrue);
    });

    test('a day exactly at its share is within it', () {
      final HeroCopy copy = _weekCopy(thursday(<WeekDay>[_day(26, spent: 1850), _day(29, spent: 0)], spentThisWeek: 1850));
      expect(copy.range.detail, 'every day within its share');
    });

    test('several days over: the most-over day, and how many more', () {
      final HeroCopy copy = _weekCopy(thursday(<WeekDay>[
        _day(26, spent: 1900),
        _day(27, spent: 2310),
        _day(28, spent: 2000),
        _day(29, spent: 0),
      ], spentThisWeek: 6210));
      expect(copy.range.detail, 'Tue was ₹460 over its share, and 2 more days');
    });

    test('two days over says "1 more day"', () {
      final HeroCopy copy = _weekCopy(thursday(<WeekDay>[_day(26, spent: 1900), _day(27, spent: 2310), _day(29, spent: 0)], spentThisWeek: 4210));
      expect(copy.range.detail, 'Tue was ₹460 over its share, and 1 more day');
    });

    test('today over its share is "Today is", not a past tense', () {
      final HeroCopy copy = _weekCopy(thursday(<WeekDay>[_day(26, spent: 1000), _day(29, spent: 2070)], spentThisWeek: 3070));
      expect(copy.range.detail, 'Today is ₹220 over its share');
    });

    test('a day with a ₹0 share is over by all it spent', () {
      final HeroCopy copy = _weekCopy(thursday(<WeekDay>[_day(26, spent: 300, share: 0), _day(29, spent: 0)], spentThisWeek: 300));
      expect(copy.range.detail, 'Mon was ₹300 over its share');
    });

    test('TalkBack hears each day by its full name with real values, and the week sentence', () {
      final HeroCopy copy = _weekCopy(thursday(<WeekDay>[
        _day(26, spent: 1240, share: 1820),
        _day(27, spent: 2310),
        _day(28, spent: 980, share: 1790),
        _day(29, spent: 420),
      ]));
      expect(
        copy.spoken,
        'Safe to spend this week: 6,150 rupees. '
        'Monday, 1,240 rupees. Tuesday, 2,310 rupees, 460 rupees over its share. Wednesday, 980 rupees. '
        'Today, 420 rupees so far. Spent 4,950 rupees this week, Tue was 460 rupees over its share.',
      );
    });

    test('Today mode keeps the forecast range line', () {
      final HeroCopy copy = _copy(thursday(<WeekDay>[_day(27, spent: 2310), _day(29, spent: 420)]));
      expect(copy.range, const RangeWords('Lasts till payday'));
    });
  });
}
