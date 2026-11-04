import 'package:intl/intl.dart';

import '../../core/money/money.dart';
import '../../core/time/calendar_date.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ledger/ledger.dart';
import 'hero_copy.dart';

/// The words for the hero's *This week* bars (SPEC BR-6a): one sentence in the range slot and one
/// spoken line per day, so the hatch never needs a key.
final class WeekCopy {
  /// Words for [summary]'s week in [strings], amounts written by [amount] and weekdays in [locale].
  const WeekCopy(this.summary, {required this.strings, required this.amount, required this.locale});

  final CycleSummary summary;
  final AppLocalizations strings;
  final String Function(Money) amount;
  final String locale;

  /// "Spent ₹4,950 this week · Tue was ₹460 over its share", or "· every day within its share".
  RangeWords get range => RangeWords(strings.weekSpent(amount(summary.spentThisWeek)), _overDetail());

  /// True when no day went over its share: the check glyph rather than the alert.
  bool get calm => !summary.week.any(_isOver);

  /// "Monday, 1,240 rupees. Tuesday, 2,310 rupees, 460 rupees over its share. … Today, 420 rupees
  /// so far", or null when the week has no days.
  String? get spokenDays => summary.week.isEmpty ? null : summary.week.map(_spokenDay).reduce(strings.spokenSentences);

  String _overDetail() {
    final List<WeekDay> over = summary.week.where(_isOver).toList();
    if (over.isEmpty) {
      return strings.weekAllWithin;
    }
    final WeekDay most = over.reduce((WeekDay a, WeekDay b) => _over(b) > _over(a) ? b : a);
    final String named = most.date == summary.today
        ? strings.weekTodayOver(amount(_over(most)))
        : strings.weekDayOver(_weekday('EEE', most.date), amount(_over(most)));
    return over.length == 1 ? named : strings.spokenPair(named, strings.weekMoreDays(over.length - 1));
  }

  String _spokenDay(WeekDay day) {
    final String spent = day.date == summary.today
        ? strings.weekTodaySpoken(amount(day.spent))
        : strings.weekDaySpoken(_weekday('EEEE', day.date), amount(day.spent));
    return _isOver(day) ? strings.spokenPair(spent, strings.overShare(amount(_over(day)))) : spent;
  }

  String _weekday(String pattern, CalendarDate date) => DateFormat(pattern, locale).format(DateTime(date.year, date.month, date.day));

  static bool _isOver(WeekDay day) => day.spent > day.share;

  static Money _over(WeekDay day) => day.spent - day.share;
}
