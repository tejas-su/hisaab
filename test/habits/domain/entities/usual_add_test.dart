import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/habits/domain/entities/forgotten_usual.dart';
import 'package:hisaab/habits/domain/entities/suggestion_state.dart';
import 'package:hisaab/habits/domain/entities/usual_add.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';

import '../../../helpers/fixtures/habits/chai_habit.dart';

void main() {
  final Entry entry = entryAt(900, chai, 20, DateTime(2026, 10, 26, 10, 5));

  group('UsualAdd', () {
    test('compares by its entry and category', () {
      expect(UsualAdd(entry: entry, category: chai), UsualAdd(entry: entry, category: chai));
      expect(UsualAdd(entry: entry, category: chai), isNot(UsualAdd(entry: entry, category: food)));
      expect(
        UsualAdd(entry: entry, category: chai),
        isNot(UsualAdd(entry: entryAt(901, chai, 20, DateTime(2026, 10, 26, 10, 5)), category: chai)),
      );
    });
  });

  group('ForgottenUsual', () {
    test('compares by its category and previous state', () {
      const Option<SuggestionState> none = Option<SuggestionState>.none();
      final Option<SuggestionState> some = Option<SuggestionState>.of(SuggestionState(categoryId: chai.id));

      expect(ForgottenUsual(categoryId: chai.id, previous: some), ForgottenUsual(categoryId: chai.id, previous: some));
      expect(ForgottenUsual(categoryId: chai.id, previous: some), isNot(ForgottenUsual(categoryId: chai.id, previous: none)));
      expect(ForgottenUsual(categoryId: chai.id, previous: none), isNot(ForgottenUsual(categoryId: 1, previous: none)));
    });
  });
}
