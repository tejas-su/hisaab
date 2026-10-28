import 'package:expense_tracker/ask_ai/domain/ask_goal.dart';
import 'package:expense_tracker/ask_ai/domain/entities/prompt_choice.dart';
import 'package:expense_tracker/ask_ai/domain/entities/prompt_text.dart';
import 'package:expense_tracker/ask_ai/domain/prompt_builder.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures/ask_ai/prompt_input.dart';
import '../../helpers/fixtures/ledger/categories.dart';
import '../../helpers/fixtures/ledger/worked_example.dart';

Entry _entry(int id, int rupees, CalendarDate date, {EntryKind kind = EntryKind.spent, String? note}) => Entry(
  id: id,
  amount: Money.fromMajor(rupees),
  kind: kind,
  categoryId: kind == EntryKind.got ? SeedCategoryIds.salary : SeedCategoryIds.food,
  date: date,
  createdAt: DateTime(date.year, date.month, date.day),
  note: note,
);

/// The worked example with [note] on its oldest entry (4 Oct), so grouping the first week drops it.
List<Entry> _withNote(String note) => <Entry>[
  _entry(1, 45000, const CalendarDate(2026, 10, 4), kind: EntryKind.got, note: note),
  ...WorkedExample.entries.skip(1),
];

PromptText _build(List<Entry> entries, {PromptChoice choice = const PromptChoice()}) =>
    PromptBuilder.build(workedPromptInput(entries: entries), choice, nameOf: englishName);

List<String> _csvDates(PromptText prompt) => prompt.text
    .split('\n')
    .where((String line) => RegExp(r'^\d{4}-\d{2}-\d{2},').hasMatch(line))
    .map((String l) => l.substring(0, 10))
    .toList();

void main() {
  group('PromptBuilder size guard (BR-15)', () {
    final int base = _build(_withNote('')).text.length;

    test('text of exactly 12,000 chars is not grouped', () {
      final PromptText prompt = _build(_withNote('x' * (12000 - base)));
      expect(prompt.text.length, 12000);
      expect(prompt.groupedWeeks, 0);
      expect(prompt.text, isNot(contains('Earlier weeks')));
    });

    test('one char over groups the oldest week', () {
      final PromptText prompt = _build(_withNote('x' * (12001 - base)));
      expect(prompt.groupedWeeks, 1);
      expect(prompt.text.length, lessThanOrEqualTo(12000));
      expect(prompt.entryCount, 6);
      expect(prompt.text.split('\n')[7], 'Earlier weeks (spent/got): 2026-10-04..2026-10-10 8,200/45,000');
      expect(prompt.text.split('\n')[8], 'Entries (CSV):');
      expect(_csvDates(prompt), <String>['2026-10-20', '2026-10-26', '2026-10-26', '2026-10-26']);
    });

    test('three busy cycles fit after grouping, deterministically', () {
      final List<Entry> entries = <Entry>[
        for (int day = 0; day < 84; day++)
          for (int n = 0; n < 20; n++)
            _entry(day * 20 + n + 1, 50 + n, const CalendarDate(2026, 8, 4).addDays(day), note: 'Lunch with the team at office'),
      ];
      const PromptChoice choice = PromptChoice(period: AskPeriod.lastThreeCycles);
      final PromptText prompt = _build(entries, choice: choice);
      expect(prompt.text.length, lessThanOrEqualTo(12000));
      expect(prompt.entryCount, entries.length);
      expect(prompt.groupedWeeks, greaterThan(0));
      final String lastGroupedDay = const CalendarDate(2026, 8, 4).addDays(prompt.groupedWeeks * 7 - 1).toIso();
      expect(_csvDates(prompt).every((String date) => date.compareTo(lastGroupedDay) > 0), isTrue);
      expect(_build(entries, choice: choice).text, prompt.text);
    });

    test('an empty week shows 0/0', () {
      final PromptText prompt = _build(<Entry>[
        _entry(1, 100, const CalendarDate(2026, 10, 5)),
        _entry(2, 200, const CalendarDate(2026, 10, 18), note: 'x' * 12000),
      ]);
      expect(prompt.groupedWeeks, 3);
      expect(
        prompt.text.split('\n')[7],
        'Earlier weeks (spent/got): 2026-10-04..2026-10-10 100/0; 2026-10-11..2026-10-17 0/0; 2026-10-18..2026-10-24 200/0',
      );
    });

    test("grouped totals are the week's spent and got sums", () {
      final PromptText prompt = _build(<Entry>[
        _entry(1, 45000, const CalendarDate(2026, 10, 4), kind: EntryKind.got),
        _entry(2, 500, const CalendarDate(2026, 10, 5), note: 'x' * 12000),
      ]);
      expect(prompt.groupedWeeks, 1);
      expect(prompt.text, contains('Earlier weeks (spent/got): 2026-10-04..2026-10-10 500/45,000\n'));
    });
  });
}
