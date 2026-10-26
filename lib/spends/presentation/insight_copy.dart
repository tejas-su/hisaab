import 'package:intl/intl.dart';

import '../../core/money/money_formatter.dart';
import '../../core/time/calendar_date.dart';
import '../../l10n/gen/app_localizations.dart';
import '../domain/entities/insight.dart';

/// The sentence and action label for an [Insight] (SPEC BR-14).
abstract final class InsightCopy {
  /// The plain sentence for [insight]; [categoryName] names a category id.
  static String sentence(
    Insight insight, {
    required AppLocalizations strings,
    required MoneyFormatter money,
    required String Function(int) categoryName,
  }) =>
      switch (insight) {
        CategoryUp(:final int categoryId, :final rise) => strings.insightCategoryUp(categoryName(categoryId), money.format(rise)),
        BiggestSpend(:final int categoryId, :final amount, :final CalendarDate date) => strings.insightBiggestSpend(
            categoryName(categoryId),
            money.format(amount),
            DateFormat('d MMM', money.locale).format(DateTime(date.year, date.month, date.day)),
          ),
        SteadiestCategory(:final int categoryId) => strings.insightSteadiest(categoryName(categoryId)),
        LimitOffer() => strings.insightLimitOffer,
      };

  /// The one next step: *Use these limits* for the offer, *See entries* otherwise.
  static String action(Insight insight, AppLocalizations strings) =>
      insight is LimitOffer ? strings.useTheseLimits : strings.seeEntries;
}
