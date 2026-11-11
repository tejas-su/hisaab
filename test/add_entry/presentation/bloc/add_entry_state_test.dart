import 'package:hisaab/add_entry/presentation/bloc/add_entry_state.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
