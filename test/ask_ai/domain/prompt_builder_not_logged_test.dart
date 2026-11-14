import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/ask_ai/domain/entities/prompt_choice.dart';
import 'package:hisaab/ask_ai/domain/entities/prompt_text.dart';
import 'package:hisaab/ask_ai/domain/prompt_builder.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/ledger.dart';

import '../../helpers/fixtures/ask_ai/prompt_input.dart';
import '../../helpers/fixtures/ledger/categories.dart';
import '../../helpers/fixtures/ledger/not_logged.dart';
import '../../helpers/fixtures/ledger/worked_example.dart';

const String _notLoggedClause =
    'Entries with the category "not logged" are corrections. When the user checked their real money it differed from this list, '
    'so one entry was added for the difference. Treat each as a one-off, not as a purchase or a habit, and do not give spending advice about it.';

const String _usedClause =
    'Entries of kind "used" are costs the user paid from money they had already set aside in a saving, '
    'such as a yearly insurance bill. That money was counted when it was put in, so it is not spending '
    'in this period and does not change the daily number. Do not add it to spending.';

const String _base =
    'You are a friendly money coach for someone in India. Reply in simple English, under 200 words.\n'
    'Use only the numbers below. Write amounts in ₹ with Indian grouping (₹1,25,000).\n'
    "If there is too little data to judge, say so. Don't name specific stocks, funds, loans or apps.\n"
    'Context: income ₹45,000/month (payday 4th), currency INR, period 2026-10-04..2026-11-03, today 2026-10-26.\n';

const String _task =
    'Task: Tell me how this period went. Give: 1) 3 things that stand out, good or bad, with ₹ amounts 2) the one change that would save the most, and how much a month 3) one habit worth keeping.';

PromptText _build(List<Entry> entries, {PromptChoice choice = const PromptChoice()}) =>
    PromptBuilder.build(workedPromptInput(entries: entries), choice, nameOf: englishName);

/// A *Not logged* fix in the export (SPEC BR-15, D188, C10).
void main() {
  final Entry spentFix = notLogged(4200, const CalendarDate(2026, 10, 26));

  group('PromptBuilder with a Not logged entry', () {
    test('an export without a fix is byte-identical to the existing golden: no clause', () {
      expect(_build(WorkedExample.entries).text, isNot(contains('not logged')));
    });

    test('golden: an export with a fix', () {
      final PromptText prompt = _build(<Entry>[...WorkedExample.entries, spentFix]);

      expect(
        prompt.text,
        '$_base'
        '$_notLoggedClause\n'
        'Spent ₹27,570, got ₹45,000. By category: Food 19,010; Home 8,200; Shopping 240; Travel 120.\n'
        'Recurring bills: Electricity 1,200 monthly on day 29; Rent 8,200 monthly on day 5.\n'
        '\n'
        'Entries (CSV):\n'
        'date,amount,kind,category,note\n'
        '2026-10-04,45000,got,Money in,\n'
        '2026-10-05,8200,spent,Home,\n'
        '2026-10-20,18950,spent,Food,\n'
        '2026-10-26,60,spent,Food,Chai & samosa\n'
        '2026-10-26,120,spent,Travel,Auto to office\n'
        '2026-10-26,240,spent,Shopping,Groceries\n'
        '2026-10-26,4200,spent,not logged,Not logged\n'
        '\n'
        '$_task',
      );
      expect(prompt.entryCount, 7);
    });

    test("a fix's CSV row is date,amount,spent,not logged,Not logged, and the Got form is got", () {
      final String spent = _build(<Entry>[spentFix]).text;
      final String got = _build(<Entry>[notLogged(1000, const CalendarDate(2026, 10, 26), got: true)]).text;

      expect(spent, contains('2026-10-26,4200,spent,not logged,Not logged'));
      expect(got, contains('2026-10-26,1000,got,not logged,Not logged'));
    });

    test('hidden notes drop the note column and the Not logged note with it', () {
      final String text = _build(<Entry>[...WorkedExample.entries, spentFix], choice: const PromptChoice(hideNotes: true)).text;

      expect(text, contains('date,amount,kind,category\n'));
      expect(text, contains('2026-10-26,4200,spent,not logged\n'));
    });

    test('the summary table and the totals exclude it, so a fix is no spending and no income (C10)', () {
      final String text = _build(<Entry>[...WorkedExample.entries, spentFix, notLogged(900, const CalendarDate(2026, 10, 26), got: true, id: 801)]).text;

      expect(text, contains('Spent ₹27,570, got ₹45,000. By category: Food 19,010; Home 8,200; Shopping 240; Travel 120.'));
    });

    test('a grouped older week does not count it as spending', () {
      final Entry oldFix = notLogged(5000, const CalendarDate(2026, 10, 6), id: 802);
      final List<Entry> many = <Entry>[
        ...WorkedExample.entries,
        oldFix,
        for (int i = 0; i < 400; i++)
          Entry(
            id: 2000 + i,
            amount: Money.fromMajor(10 + i % 7),
            kind: EntryKind.spent,
            categoryId: SeedCategoryIds.food,
            date: CalendarDate(2026, 10, 5 + i % 20),
            createdAt: DateTime(2026, 10, 5),
            note: 'A fairly long note so the export passes the length limit ${i % 9}',
          ),
      ];

      final PromptText prompt = _build(many);

      expect(prompt.groupedWeeks, greaterThan(0));
      expect(prompt.text, isNot(contains('5000/')));
    });

    test('an export with both a fix and a used entry has both clauses, Not logged first', () {
      final Entry used = Entry(
        id: 7,
        amount: Money.fromMajor(4000),
        kind: EntryKind.used,
        categoryId: SeedCategoryIds.saved,
        date: const CalendarDate(2026, 10, 20),
        createdAt: DateTime(2026, 10, 20),
        note: 'Insurance',
        savingId: 5,
      );

      final String text = _build(<Entry>[...WorkedExample.entries, spentFix, used]).text;

      expect(text, contains('$_notLoggedClause\n$_usedClause\n'));
    });
  });
}
