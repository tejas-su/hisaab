import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/time/calendar_date.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ledger/ledger.dart';
import '../../../../ledger/presentation/rule_words.dart';

/// The bill sheet's derived words: the stamp, short dates and icon names (SPEC BR-9, D118).
extension BillSheetCopy on BuildContext {
  /// The stamp's text for [status], or null when there is no stamp; a saving's [kind] says
  /// "Put in" (D120), and a card bill's [mode] says "Paid", never "Went out" (D123).
  String? stampText(BillStatus status, {EntryKind kind = EntryKind.spent, AmountMode mode = AmountMode.fixed}) {
    final AppLocalizations strings = AppLocalizations.of(this);
    // why: daysAway counts from today, so the stamp needs no clock of its own.
    final CalendarDate today = status.nextDate.addDays(-status.daysAway);
    final bool card = mode == AmountMode.card;
    return switch (status.stamp) {
      BillStampDue(:final int days) => strings.ruleStampDue(kind, days),
      BillStampCounted(:final CalendarDate on) when on == today => card ? strings.billStampPaidToday : strings.ruleStampCountedToday(kind),
      BillStampCounted(:final CalendarDate on) => card ? strings.billStampPaid(shortDate(on)) : strings.ruleStampCounted(kind, shortDate(on)),
      BillStampWaiting() => strings.billStampWaiting,
      BillStampNone() => null,
    };
  }

  /// The sheet's footer for [status]: the next date, or for a waiting bill the day it went out
  /// and where to answer it (D123).
  String footText(BillStatus status, {required EntryKind kind, required AmountMode mode}) {
    final AppLocalizations strings = AppLocalizations.of(this);
    final String date = shortDate(status.nextDate);
    return switch (status.stamp) {
      BillStampWaiting() => mode == AmountMode.card ? strings.billWaitingCard(date) : strings.billWaitingVaries(date),
      BillStampDue() || BillStampCounted() || BillStampNone() => strings.ruleNext(kind, date),
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
