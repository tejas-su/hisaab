import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/money/money_formatter.dart';
import 'package:hisaab/l10n/gen/app_localizations.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/month_story.dart';
import 'package:hisaab/spends/presentation/month_story_copy.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/fixtures/ledger/categories.dart';

void main() {
  late AppLocalizations strings;
  final AmountWriter shown = MonthStoryCopy.shown(MoneyFormatter());

  setUpAll(() async => strings = await AppLocalizations.delegate.load(const Locale('en', 'IN')));

  StoryComparison change(int rupees) =>
      StoryComparison(previousSpent: Money.fromMajor(47100), change: Money.fromMajor(rupees), moves: const <CategoryMove>[]);

  group('MonthStoryCopy.change (BR-20 page 5)', () {
    test('less, more and the same', () {
      expect(MonthStoryCopy.change(change(-7500), 'August', strings, shown), '₹7,500 less than August');
      expect(MonthStoryCopy.change(change(1200), 'August', strings, shown), '₹1,200 more than August');
      expect(MonthStoryCopy.change(change(0), 'August', strings, shown), 'The same as August');
    });
  });

  group('MonthStoryCopy.move', () {
    test('a fall and a rise', () {
      final Category food = seedCategories.first;
      expect(MonthStoryCopy.move(CategoryMove(category: food, change: Money.fromMajor(-2200)), strings, shown), '₹2,200 less');
      expect(MonthStoryCopy.move(CategoryMove(category: food, change: Money.fromMajor(1200)), strings, shown), '₹1,200 more');
    });
  });

  group('MonthStoryCopy.weekday', () {
    test('names every weekday in the plural', () {
      final List<String> lines = <String>[
        for (int day = DateTime.monday; day <= DateTime.sunday; day++)
          MonthStoryCopy.weekday(StoryWeekday(weekday: day, count: 4, total: Money.fromMajor(100)), strings, shown),
      ];
      expect(lines.first, 'Your 4 Mondays came to ₹100.');
      expect(lines.last, 'Your 4 Sundays came to ₹100.');
      expect(lines.toSet(), hasLength(7));
    });
  });
}
