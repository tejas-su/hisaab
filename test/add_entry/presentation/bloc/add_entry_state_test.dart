import 'package:hisaab/add_entry/presentation/bloc/add_entry_event.dart';
import 'package:hisaab/add_entry/presentation/bloc/add_entry_state.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fixtures/habits/chai_habit.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  test('tray states compare by their fields', () {
    final EntryForm form = EntryForm(
      kind: EntryKind.spent,
      rupees: 60,
      date: WorkedExample.today,
      today: WorkedExample.today,
      earliestDate: WorkedExample.today,
      tiles: seedCategories,
    );
    expect(AddEntrySaving(form, categoryId: 1).props, <Object?>[form, 1]);
    expect(AddEntryFinished(form, categoryId: 1).props, <Object?>[form, 1]);
    expect(AddEntrySaving(form, categoryId: 1), AddEntrySaving(form, categoryId: 1));
    expect(AddEntryEditing(form, rejections: 2, failed: true).props, <Object?>[form, 2, true]);
  });

  group('your usual (FR-AD-10)', () {
    final EntryForm form = EntryForm(
      kind: EntryKind.spent,
      rupees: 0,
      date: WorkedExample.today,
      today: WorkedExample.today,
      earliestDate: WorkedExample.today,
      tiles: seedCategories,
    );
    final Option<UsualSpend> usual = Option<UsualSpend>.of(UsualSpend(category: chai, amount: Money.fromMajor(20)));
    final Entry entry = entryAt(1, chai, 20, WorkedExample.now);

    test('EntryForm compares by usual and copies it', () {
      expect(form.usual, const Option<UsualSpend>.none());
      expect(form.copyWith(usual: usual), isNot(form));
      expect(form.copyWith(usual: usual).usual, usual);
      expect(form.copyWith(usual: usual).copyWith(rupees: 5).usual, usual);
      expect(form.copyWith(usual: usual).copyWith(usual: const Option<UsualSpend>.none()), form);
    });

    test('AddEntryFinished compares by added', () {
      final AddEntryFinished plain = AddEntryFinished(form, categoryId: 13);
      final AddEntryFinished added = AddEntryFinished(form, categoryId: 13, added: Option<Entry>.of(entry));
      expect(plain.added, const Option<Entry>.none());
      expect(added, isNot(plain));
      expect(added, AddEntryFinished(form, categoryId: 13, added: Option<Entry>.of(entry)));
      expect(added, isNot(AddEntryFinished(form, categoryId: 13, added: Option<Entry>.of(entryAt(2, chai, 20, WorkedExample.now)))));
    });

    test('AddEntryUsualPicked compares equal', () {
      expect(const AddEntryUsualPicked(), const AddEntryUsualPicked());
      expect(const AddEntryUsualPicked().props, isEmpty);
    });
  });
}
