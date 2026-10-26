import 'package:intl/intl.dart';

import 'money.dart';

/// The single place that turns [Money] into text; never shows paise (SPEC §3, DECISIONS D12).
final class MoneyFormatter {
  /// Creates a formatter for [locale]; `en_IN` gives lakh/crore grouping.
  MoneyFormatter({this.locale = 'en_IN'});

  /// The `intl` locale used for grouping and compact suffixes.
  final String locale;

  /// Formats [money] as a whole-unit amount with its symbol, e.g. `₹1,25,000`.
  String format(Money money) =>
      NumberFormat.currency(locale: locale, symbol: money.currency.symbol, decimalDigits: 0)
          .format(money.floorMajor);

  /// Formats [money] compactly for chart axes, e.g. `₹1.25L`, `₹1.25Cr`.
  String compact(Money money) =>
      NumberFormat.compactCurrency(locale: locale, symbol: money.currency.symbol).format(money.floorMajor);

  /// Formats [money] without a symbol, for spoken labels such as "1,430 rupees".
  String digits(Money money) => NumberFormat.decimalPattern(locale).format(money.floorMajor);
}
