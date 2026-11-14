import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/habits/domain/entities/day_type.dart';
import 'package:hisaab/habits/domain/entities/habit_index.dart';
import 'package:hisaab/habits/domain/entities/habit_inputs.dart';
import 'package:hisaab/habits/domain/entities/suggestion_state.dart';
import 'package:hisaab/habits/domain/habit_index_builder.dart';
import 'package:hisaab/ledger/domain/budget_suggester.dart';
import 'package:hisaab/ledger/domain/entities/budget_settings.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/entities/bill_skip.dart';
import 'package:hisaab/ledger/domain/entities/category.dart';
import 'package:hisaab/shortcuts/domain/projection/projected_book.dart';
import 'package:hisaab/spends/domain/category_shares.dart';
import 'package:hisaab/spends/domain/entities/pace_series.dart';
import 'package:hisaab/spends/domain/insight_rules.dart';
import 'package:hisaab/spends/domain/entities/insight.dart';

import '../../helpers/fixtures/habits/chai_habit.dart';
import '../../helpers/fixtures/ledger/categories.dart';
import '../../helpers/fixtures/ledger/not_logged.dart';
import '../../helpers/fixtures/ledger/worked_example.dart';

const PayCycle _cycle = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3));
const CalendarDate _today = WorkedExample.today;

/// BR-18: a fix is never spending, so no reader that means "spending" counts it (BR-12 to BR-17,
/// FR-SP-3, FR-WG-5, FR-SP-6). Each test adds a big fix beside the worked example's entries.
void main() {
  final Entry fix = notLogged(9000, _today.addDays(-1));
  final List<Entry> withFix = <Entry>[...WorkedExample.entries, fix];

  group('a fix is not spending', () {
    test('a suggested limit ignores it (BR-12)', () {
      expect(BudgetSuggester.suggest(withFix), BudgetSuggester.suggest(WorkedExample.entries));
      expect(BudgetSuggester.suggest(withFix).containsKey(fix.categoryId), isFalse);
    });

    test("category shares ignore it (BR-13)", () {
      expect(CategoryShares.of(withFix, seedCategories), CategoryShares.of(WorkedExample.entries, seedCategories));
    });

    test('the pace chart ignores it (FR-SP-3)', () {
      final PaceSeries plain =
          PaceSeries.of(WorkedExample.entries, cycle: _cycle, asOf: _today, budget: Money.fromMajor(45000)).getOrElse(() => fail('none'));
      final PaceSeries with9000 =
          PaceSeries.of(withFix, cycle: _cycle, asOf: _today, budget: Money.fromMajor(45000)).getOrElse(() => fail('none'));

      expect(with9000.spentByDay, plain.spentByDay);
    });

    test('the biggest-spend insight never names a fix (BR-14)', () {
      final List<Insight> insights = InsightRules.evaluate(
        InsightWindow(cycle: _cycle, asOf: _today, entries: <Entry>[...WorkedExample.entries, notLogged(90000, _today)]),
        previous: const Option<InsightWindow>.none(),
      );

      expect(insights.whereType<BiggestSpend>().map((BiggestSpend s) => s.categoryId), isNot(contains(SeedCategoryIds.notLogged)));
    });

    test("the widget's bites ignore it (FR-WG-5)", () {
      final ProjectedBook book = ProjectedBook(
        entries: <Entry>[...WorkedExample.entries, notLogged(900, _today)],
        rules: WorkedExample.rules,
        skips: const <BillSkip>[],
        settings: const BudgetSettings(),
        firstLogged: const Option<CalendarDate>.of(CalendarDate(2026, 10, 4)),
      );

      expect(book.typedSpendsOn(_today).any((Entry e) => e.isNotLogged), isFalse);
      expect(book.typedSpendsOn(_today), hasLength(3));
    });

    test('a fix does not make a day active for a habit (BR-17)', () {
      final List<CalendarDate> weekdays = daysBefore(_today, DayType.weekday);
      final List<Entry> nineActiveDays = entriesOn(weekdays.skip(10).take(9), chai, firstId: 201);
      final Entry tenthDayFix = notLogged(500, weekdays.last, id: 950);
      final Entry stampedLoggedThatDay = Entry(
        id: tenthDayFix.id,
        amount: tenthDayFix.amount,
        kind: tenthDayFix.kind,
        categoryId: tenthDayFix.categoryId,
        date: tenthDayFix.date,
        createdAt: DateTime(tenthDayFix.date.year, tenthDayFix.date.month, tenthDayFix.date.day, 10, 5),
        isNotLogged: true,
      );

      final HabitIndex index = _index(<Entry>[...nineActiveDays, stampedLoggedThatDay]);

      expect(index.habits, isEmpty);
    });
  });
}

HabitIndex _index(List<Entry> entries) => HabitIndexBuilder.build(
      HabitInputs(entries: entries, categories: <Category>[...seedCategories, chai], states: const <int, SuggestionState>{}),
      today: _today,
    );
