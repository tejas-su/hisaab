import 'package:expense_tracker/ask_ai/domain/ask_goal.dart';
import 'package:expense_tracker/ask_ai/domain/entities/prompt_choice.dart';
import 'package:expense_tracker/ask_ai/domain/entities/prompt_text.dart';
import 'package:expense_tracker/ask_ai/domain/prompt_builder.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_rule.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/fixtures/ask_ai/prompt_input.dart';
import '../../helpers/fixtures/ledger/categories.dart';
import '../../helpers/fixtures/ledger/worked_example.dart';

const String _golden =
    'You are a friendly money coach. Be specific, use my numbers, no jargon.\n'
    'Context: income ₹45,000/month (payday 4th), currency INR, period 2026-10-04..2026-11-03, today 2026-10-26.\n'
    'Spent ₹27,570, got ₹45,000. By category: Food 19,010; Home 8,200; Shopping 240; Travel 120.\n'
    'Recurring bills: Electricity 1,200 monthly on day 29; Rent 8,200 monthly on day 5.\n'
    '\n'
    'Entries (CSV):\n'
    'date,amount,kind,category,note\n'
    '2026-10-04,45000,got,Salary,\n'
    '2026-10-05,8200,spent,Home,\n'
    '2026-10-20,18950,spent,Food,\n'
    '2026-10-26,60,spent,Food,Chai & samosa\n'
    '2026-10-26,120,spent,Travel,Auto to office\n'
    '2026-10-26,240,spent,Shopping,Groceries\n'
    '\n'
    'Task: Review my month. Give: 1) the 3 biggest problems 2) 3 concrete savings with ₹ amounts 3) a budget per category for next month 4) one habit to change.';

Entry _entry(int id, int rupees, CalendarDate date, {int categoryId = SeedCategoryIds.food, String? note}) => Entry(
  id: id,
  amount: Money.fromMajor(rupees),
  kind: EntryKind.spent,
  categoryId: categoryId,
  date: date,
  createdAt: DateTime(date.year, date.month, date.day),
  note: note,
);

PromptText _build({PromptChoice choice = const PromptChoice(), List<Entry>? entries}) =>
    PromptBuilder.build(workedPromptInput(entries: entries), choice, nameOf: englishName);

List<String> _lines(PromptText prompt) => prompt.text.split('\n');

void main() {
  group('PromptBuilder.build (BR-15)', () {
    test('builds the worked example byte for byte', () {
      final PromptText prompt = _build();
      expect(prompt.text, _golden);
      expect(prompt.entryCount, 6);
      expect(prompt.groupedWeeks, 0);
    });

    test('same input gives identical text', () {
      expect(_build().text, _build().text);
    });

    test('hideNotes drops the note column', () {
      final PromptText prompt = _build(choice: const PromptChoice(hideNotes: true));
      expect(
        _lines(prompt),
        containsAllInOrder(<String>['date,amount,kind,category', '2026-10-04,45000,got,Salary', '2026-10-26,60,spent,Food']),
      );
      expect(prompt.text, isNot(contains('Chai')));
      expect(prompt.text, isNot(contains('note')));
    });

    test('a note with a comma stays one field', () {
      final PromptText prompt = _build(entries: <Entry>[_entry(1, 90, WorkedExample.today, note: 'Rice, dal')]);
      expect(_lines(prompt), contains('2026-10-26,90,spent,Food,"Rice, dal"'));
    });

    test('a renamed category with a comma is quoted in CSV', () {
      final List<Category> categories = <Category>[
        for (final Category c in seedCategories)
          c.id == SeedCategoryIds.food
              ? Category(id: c.id, key: c.key, iconKey: c.iconKey, kind: c.kind, sort: c.sort, customName: 'Food, snacks')
              : c,
      ];
      final PromptText prompt = PromptBuilder.build(
        workedPromptInput(entries: <Entry>[_entry(1, 90, WorkedExample.today)], categories: categories),
        const PromptChoice(),
        nameOf: englishName,
      );
      expect(_lines(prompt), contains('2026-10-26,90,spent,"Food, snacks",'));
    });

    test('a category limit shows in the summary', () {
      final List<Category> categories = <Category>[
        for (final Category c in seedCategories)
          c.id == SeedCategoryIds.food
              ? Category(
                  id: c.id,
                  key: c.key,
                  iconKey: c.iconKey,
                  kind: c.kind,
                  sort: c.sort,
                  limit: Option<Money>.of(Money.fromMajor(10000)),
                )
              : c,
      ];
      final PromptText prompt = PromptBuilder.build(workedPromptInput(categories: categories), const PromptChoice(), nameOf: englishName);
      expect(
        _lines(prompt)[2],
        'Spent ₹27,570, got ₹45,000. By category: Food 19,010 (limit 10,000 a month); Home 8,200; Shopping 240; Travel 120.',
      );
    });

    test('equal spends keep the fixed category order', () {
      final PromptText prompt = _build(
        entries: <Entry>[
          _entry(1, 100, WorkedExample.today, categoryId: SeedCategoryIds.travel),
          _entry(2, 100, WorkedExample.today),
        ],
      );
      expect(_lines(prompt)[2], 'Spent ₹200, got ₹0. By category: Food 100; Travel 100.');
    });

    test('last three cycles widens the period and the entries', () {
      final PromptText prompt = _build(
        choice: const PromptChoice(period: AskPeriod.lastThreeCycles),
        entries: <Entry>[...WorkedExample.entries, _entry(7, 300, const CalendarDate(2026, 9, 10))],
      );
      expect(_lines(prompt)[1], contains('period 2026-08-04..2026-11-03'));
      expect(prompt.entryCount, 7);
      expect(_lines(prompt)[7], '2026-09-10,300,spent,Food,');
    });

    test('this cycle leaves out older entries', () {
      final PromptText prompt = _build(entries: <Entry>[...WorkedExample.entries, _entry(7, 300, const CalendarDate(2026, 9, 10))]);
      expect(prompt.entryCount, 6);
      expect(prompt.text, isNot(contains('2026-09-10')));
    });

    test('entries after today are left out', () {
      final PromptText prompt = _build(entries: <Entry>[...WorkedExample.entries, _entry(7, 300, const CalendarDate(2026, 10, 27))]);
      expect(prompt.entryCount, 6);
      expect(prompt.text, isNot(contains('2026-10-27')));
    });

    test('no bills and no spends read none', () {
      final PromptText prompt = PromptBuilder.build(
        workedPromptInput(entries: const <Entry>[], bills: const <RecurringRule>[]),
        const PromptChoice(),
        nameOf: englishName,
      );
      expect(_lines(prompt)[2], 'Spent ₹0, got ₹0. By category: none.');
      expect(_lines(prompt)[3], 'Recurring bills: none.');
      expect(prompt.entryCount, 0);
    });

    test('a bill that is not monthly names its frequency', () {
      final RecurringRule gym = RecurringRule(
        id: 9,
        label: 'Gym',
        amount: Money.fromMajor(500),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.food,
        schedule: const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 5)),
        nextDue: const CalendarDate(2026, 10, 27),
      );
      final PromptText prompt = PromptBuilder.build(
        workedPromptInput(bills: <RecurringRule>[gym]),
        const PromptChoice(),
        nameOf: englishName,
      );
      expect(_lines(prompt)[3], 'Recurring bills: Gym 500 weekly.');
    });

    group('task line per goal', () {
      const Map<AskGoal, String> tasks = <AskGoal, String>{
        AskGoal.reviewMonth: 'Task: Review my month. Give: 1) the 3 biggest problems 2) 3 concrete savings with ₹ amounts 3) a budget per category for next month 4) one habit to change.',
        AskGoal.helpMeSave:
            'Task: Help me save more. Give 5 specific cuts with ₹ amounts a month, easiest first, and the total I would save.',
        AskGoal.makeBudget: 'Task: Make me a monthly budget per category that fits my income and leaves room to save. Show a table with ₹ amounts and one line on why for each.',
        AskGoal.onTrack: 'Task: Am I on track to last until my next payday? Compare my spending pace with the days left and tell me how much I can spend each day from now.',
      };
      for (final MapEntry<AskGoal, String> task in tasks.entries) {
        test('${task.key.name} ends with its task line', () {
          expect(_lines(_build(choice: PromptChoice(goal: task.key))).last, task.value);
        });
      }

      test('own question is trimmed', () {
        final PromptText prompt = _build(
          choice: const PromptChoice(goal: AskGoal.ownQuestion, question: '  Can I buy a bike?  '),
        );
        expect(_lines(prompt).last, 'Task: Can I buy a bike?');
      });
    });

    group('payday wording per pay rule', () {
      String context(PayRule rule, {Option<RecurringRule>? income}) => _lines(
        PromptBuilder.build(
          workedPromptInput(payRule: rule, incomeRule: income),
          const PromptChoice(),
          nameOf: englishName,
        ),
      )[1];

      test('last day of the month', () {
        expect(context(const LastDayOfMonth()), startsWith('Context: income ₹45,000/month (payday last day of the month),'));
      });

      test('weekly pay reads per week and names the weekday', () {
        final RecurringRule weekly = WorkedExample.salary.copyWith(
          amount: Money.fromMajor(10000),
          schedule: const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 19)),
        );
        expect(
          context(const WeeklyOn(DateTime.monday), income: Option<RecurringRule>.of(weekly)),
          startsWith('Context: income ₹10,000/week (paid every Monday),'),
        );
      });

      test('no income rule reads varies', () {
        expect(context(const IrregularIncome(), income: const Option<RecurringRule>.none()), startsWith('Context: income varies,'));
      });

      test('irregular income with a rule says no fixed payday', () {
        expect(context(const IrregularIncome()), startsWith('Context: income ₹45,000/month (no fixed payday),'));
      });

      const Map<int, String> ordinals = <int, String>{
        1: '1st', 2: '2nd', 3: '3rd', 4: '4th', 11: '11th', 12: '12th', 13: '13th', //
        21: '21st', 22: '22nd', 23: '23rd', 31: '31st',
      };
      for (final MapEntry<int, String> ordinal in ordinals.entries) {
        test('payday ${ordinal.key} reads ${ordinal.value}', () {
          expect(context(MonthlyOnDay(ordinal.key)), contains('(payday ${ordinal.value})'));
        });
      }
    });
  });
}
