import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hisaab/core/design/app_icons.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/money/money_formatter.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/l10n/gen/app_localizations.dart';
import 'package:hisaab/spends/domain/entities/cycle_bar.dart';
import 'package:hisaab/spends/domain/entities/money_split.dart';
import 'package:hisaab/spends/domain/entities/spends_comparison.dart';
import 'package:hisaab/spends/presentation/month_story_copy.dart';
import 'package:hisaab/spends/presentation/spends_graph_copy.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fixtures/ledger/september_story.dart';

Money _r(int rupees) => Money.fromMajor(rupees);

void main() {
  late SpendsGraphCopy copy;
  const PayCycle week = PayCycle(start: CalendarDate(2026, 10, 12), end: CalendarDate(2026, 10, 18));

  setUpAll(() async {
    await initializeDateFormatting('en_IN');
    final AppLocalizations strings = await AppLocalizations.delegate.load(const Locale('en', 'IN'));
    final MoneyFormatter money = MoneyFormatter();
    copy = SpendsGraphCopy(
      strings: strings,
      shown: MonthStoryCopy.shown(money),
      spoken: MonthStoryCopy.spoken(strings, money),
      locale: 'en_IN',
      today: SeptemberStory.today,
    );
  });

  CycleBar bar({int income = 45000, int spent = 39600, int saved = 1000, bool running = false, int daysLeft = 0}) => CycleBar(
        cycle: SeptemberStory.september,
        cyclesBack: 1,
        split: MoneySplit(income: _r(income), bills: Money.zero, saved: _r(saved), everyday: _r(spent), notLogged: Money.zero),
        isRunning: running,
        daysLeft: daysLeft,
      );

  group('SpendsGraphCopy.comparison (FR-SP-3a)', () {
    test('by this day, whole cycle, the same, and the week before', () {
      expect(copy.comparison(SpendsComparison(change: _r(-4760), wholeCycle: false), SeptemberStory.september).shown,
          '₹4,760 less than by this day in September.');
      expect(copy.comparison(SpendsComparison(change: _r(-4760), wholeCycle: false), SeptemberStory.september).spoken,
          '4,760 rupees less than by this day in September.');
      expect(copy.comparison(SpendsComparison(change: _r(1200), wholeCycle: true), SeptemberStory.august).shown, '₹1,200 more than in August.');
      expect(copy.comparison(SpendsComparison(change: _r(-60), wholeCycle: true), SeptemberStory.august).shown, 'Same as in August.');
      expect(copy.comparison(SpendsComparison(change: _r(800), wholeCycle: false), week).shown, '₹800 more than by this day the week before.');
    });

    test('arrows: down for less, up for more, none for the same', () {
      expect(copy.comparison(SpendsComparison(change: _r(-200), wholeCycle: true), SeptemberStory.august).arrow, AppIcons.less);
      expect(copy.comparison(SpendsComparison(change: _r(200), wholeCycle: true), SeptemberStory.august).arrow, AppIcons.more);
      expect(copy.comparison(SpendsComparison(change: _r(50), wholeCycle: true), SeptemberStory.august).arrow, isNull);
    });
  });

  group('SpendsGraphCopy.rowChange (FR-SP-4 AC-R2)', () {
    test('a short month name, or the week before', () {
      expect(copy.rowChange(_r(1200), SeptemberStory.september).shown, '₹1,200 more than Sept');
      expect(copy.rowChange(_r(-900), week).shown, '₹900 less than the week before');
      expect(copy.rowChange(Money.zero, SeptemberStory.september).shown, 'Same as Sept');
    });
  });

  group('SpendsGraphCopy.readOut (FR-SP-8)', () {
    test('left over, past what came in, exactly used, no money in, and no saving', () {
      expect(copy.readOut(bar(), copy.shown), 'September: spent ₹39,600, saved ₹1,000. ₹4,400 left over.');
      expect(copy.readOut(bar(spent: 47100), copy.shown), 'September: spent ₹47,100, saved ₹1,000. ₹3,100 more than came in.');
      expect(copy.readOut(bar(spent: 44000), copy.shown), 'September: spent ₹44,000, saved ₹1,000. Nothing left over.');
      expect(copy.readOut(bar(income: 0), copy.shown), 'September: spent ₹39,600, saved ₹1,000.');
      expect(copy.readOut(bar(saved: 0), copy.shown), 'September: spent ₹39,600. ₹5,400 left over.');
    });

    test('the running cycle says so far and the days to go; an empty one says nothing spent', () {
      expect(copy.readOut(bar(running: true, daysLeft: 8), copy.shown), 'September so far: spent ₹39,600, saved ₹1,000. 8 days to go.');
      expect(copy.readOut(bar(running: true, daysLeft: 1), copy.shown), endsWith('1 day to go.'));
      expect(copy.readOut(bar(spent: 0, saved: 0), copy.shown), 'September: nothing spent or saved.');
    });
  });

  group('SpendsGraphCopy.stripHeading (FR-SP-8)', () {
    MonthsStrip strip(List<int> lefts) => MonthsStrip(<CycleBar>[
          for (final int left in lefts) bar(spent: 44000 - left),
          bar(running: true, daysLeft: 3),
        ]);

    test('some, none, both and all', () {
      expect(copy.stripHeading(strip(<int>[100, -100, 100]), 4), ('Last 4 months', 'Money was left over in 2 of the last 3 months.'));
      expect(copy.stripHeading(strip(<int>[-100, 0]), 3).$2, 'Nothing was left over in the last 2 months.');
      expect(copy.stripHeading(strip(<int>[100, 100]), 3).$2, 'Money was left over in both months.');
      expect(copy.stripHeading(strip(<int>[100, 100, 100]), 4).$2, 'Money was left over in all 3 months.');
    });

    test('no count when no finished cycle had money in', () {
      expect(copy.stripHeading(MonthsStrip(<CycleBar>[bar(income: 0), bar(running: true)]), 2).$2, isNull);
    });

    test('labels: a short month, or a week\'s start date', () {
      expect(copy.barLabel(SeptemberStory.september), 'Sept');
      expect(copy.barLabel(week), '12 Oct');
    });
  });
}
