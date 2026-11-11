import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/money/money_formatter.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/l10n/gen/app_localizations.dart';
import 'package:hisaab/spends/domain/entities/insight.dart';
import 'package:hisaab/spends/presentation/insight_copy.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

final AppLocalizations _strings = lookupAppLocalizations(const Locale('en'));

String _name(int id) => id == 1 ? 'Food' : 'Travel';

String _sentence(Insight insight) =>
    InsightCopy.sentence(insight, strings: _strings, money: MoneyFormatter(), categoryName: _name, previousCycle: 'September');

void main() {
  setUpAll(() => initializeDateFormatting('en_IN'));

  group('InsightCopy (BR-14)', () {
    final List<(Insight, String, String)> cases = <(Insight, String, String)>[
      (CategoryUp(categoryId: 1, rise: Money.fromMajor(1900)), 'Food spending is ₹1,900 more than in September.', 'See Food entries'),
      (
        BiggestSpend(categoryId: 2, amount: Money.fromMajor(1930), date: const CalendarDate(2026, 10, 31)),
        'Your biggest Travel spend was ₹1,930 on 31 Oct.',
        'See Travel entries',
      ),
      (const SteadiestCategory(categoryId: 1), 'Food spending stays about the same every week.', 'See Food entries'),
      (
        LimitOffer(limits: <int, Money>{1: Money.fromMajor(10000)}),
        "Set limits from September's spending? Each one is rounded up to the next ₹500.",
        'Use these limits',
      ),
    ];
    for (final (Insight insight, String sentence, String action) in cases) {
      test('${insight.runtimeType}: "$sentence" / $action', () {
        expect(_sentence(insight), sentence);
        expect(InsightCopy.action(insight, _strings, categoryName: _name), action);
      });
    }
  });
}
