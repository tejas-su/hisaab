import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/time/calendar_date.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/ledger.dart';

/// The bill sheet's derived words: the stamp, short dates and icon names (SPEC BR-9, D118).
extension BillSheetCopy on BuildContext {
  /// The stamp's text for [status], or null when the bill has no stamp.
  String? stampText(BillStatus status) {
    final AppLocalizations strings = AppLocalizations.of(this);
    // why: daysAway counts from today, so the stamp needs no clock of its own.
    final CalendarDate today = status.nextDate.addDays(-status.daysAway);
    return switch (status.stamp) {
      BillStampDue(:final int days) => strings.billStampDue(days),
      BillStampCounted(:final CalendarDate on) when on == today => strings.billStampCountedToday,
      BillStampCounted(:final CalendarDate on) => strings.billStampCounted(shortDate(on)),
      BillStampNone() => null,
    };
  }

  /// [date] as "29 Oct" in the app's locale.
  String shortDate(CalendarDate date) =>
      DateFormat('d MMM', Localizations.localeOf(this).toString()).format(DateTime(date.year, date.month, date.day));

  /// The name of [icon], e.g. "TV & apps".
  String iconName(BillIcon icon) => AppLocalizations.of(this).billIconName(icon.value);

  /// "1,200 rupees", for screen readers.
  String spokenMoney(RecurringRule rule) => AppLocalizations.of(this).spokenAmount(money.digits(rule.amount));
}
