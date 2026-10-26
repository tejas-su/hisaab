import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/money/money_formatter.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/l10n/gen/app_localizations.dart';
import 'package:expense_tracker/spends/domain/entities/insight.dart';
import 'package:expense_tracker/spends/presentation/insight_copy.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final AppLocalizations _strings = lookupAppLocalizations(const Locale('en'));

String _sentence(Insight insight) =>
    InsightCopy.sentence(insight, strings: _strings, money: MoneyFormatter(), categoryName: (int id) => id == 1 ? 'Food' : 'Travel');

void main() {
  setUpAll(() => initializeDateFormatting('en_IN'));

  group('InsightCopy (BR-14)', () {
    final List<(Insight, String, String)> cases = <(Insight, String, String)>[
      (CategoryUp(categoryId: 1, rise: Money.fromMajor(1900)), 'Food is up ₹1,900 from last month.', 'See entries'),
      (
        BiggestSpend(categoryId: 2, amount: Money.fromMajor(1930), date: const CalendarDate(2026, 10, 31)),
        'Your biggest Travel spend was ₹1,930 on 31 Oct.',
        'See entries',
      ),
      (const SteadiestCategory(categoryId: 1), 'Food is your steadiest spend.', 'See entries'),
      (
        LimitOffer(limits: <int, Money>{1: Money.fromMajor(10000)}),
        "Use last month's spending as limits? Each is rounded up to the next ₹500.",
        'Use these limits',
      ),
    ];
    for (final (Insight insight, String sentence, String action) in cases) {
      test('${insight.runtimeType}: "$sentence" / $action', () {
        expect(_sentence(insight), sentence);
        expect(InsightCopy.action(insight, _strings), action);
      });
    }
  });
}
