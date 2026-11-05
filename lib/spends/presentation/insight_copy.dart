import 'package:intl/intl.dart';

import '../../core/money/money.dart';
import '../../core/money/money_formatter.dart';
import '../../core/time/calendar_date.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ledger/ledger.dart';
import '../domain/entities/insight.dart';

/// The sentence and action label for an [Insight] (SPEC BR-14).
abstract final class InsightCopy {
  /// The plain sentence for [insight]; [categoryName] names a category id, and [previousCycle]
  /// names the cycle before the one shown, as the cycle switcher does ("September").
  static String sentence(
    Insight insight, {
    required AppLocalizations strings,
    required MoneyFormatter money,
    required String Function(int) categoryName,
    required String previousCycle,
  }) =>
      switch (insight) {
        CategoryUp(:final int categoryId, :final rise) =>
          strings.insightCategoryUp(categoryName(categoryId), money.format(rise), previousCycle),
        BiggestSpend(:final int categoryId, :final amount, :final CalendarDate date) => strings.insightBiggestSpend(
            categoryName(categoryId),
            money.format(amount),
            DateFormat('d MMM', money.locale).format(DateTime(date.year, date.month, date.day)),
          ),
        SteadiestCategory(:final int categoryId) => strings.insightSteadiest(categoryName(categoryId)),
        LimitOffer() => strings.insightLimitOffer(previousCycle, money.format(Money.fromMajor(BudgetSuggester.roundingMajor))),
      };

  /// The one next step: *Use these limits* for the offer, *See {category} entries* otherwise,
  /// with [categoryName] naming the category id.
  static String action(Insight insight, AppLocalizations strings, {required String Function(int) categoryName}) =>
      switch (insight) {
        LimitOffer() => strings.useTheseLimits,
        CategoryUp(:final int categoryId) ||
        BiggestSpend(:final int categoryId) ||
        SteadiestCategory(:final int categoryId) =>
          strings.seeEntries(categoryName(categoryId)),
      };
}
