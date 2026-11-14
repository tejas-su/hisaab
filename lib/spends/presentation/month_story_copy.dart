import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';

import '../../core/money/money.dart';
import '../../core/money/money_formatter.dart';
import '../../core/time/calendar_date.dart';
import '../../l10n/gen/app_localizations.dart';
import '../domain/entities/month_story.dart';
import 'widgets/day_bars_painter.dart';

/// Writes an amount: `₹4,400` on screen, "4,400 rupees" for a screen reader.
typedef AmountWriter = String Function(Money amount);

/// The month story's sentences (SPEC BR-20, FR-SP-7), written once for the screen and once for
/// TalkBack by passing a different [AmountWriter].
abstract final class MonthStoryCopy {
  static const List<String> _weekdays = <String>['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

  /// `₹4,400` through [money].
  static AmountWriter shown(MoneyFormatter money) => money.format;

  /// "4,400 rupees" through [money].
  static AmountWriter spoken(AppLocalizations strings, MoneyFormatter money) =>
      (Money amount) => strings.spokenAmount(money.digits(amount));

  /// Page 2's and the card's headline: left over, more than came in, or the spend alone.
  static String headline(MonthStory story, AppLocalizations strings, AmountWriter amount) {
    if (!story.hasIncome) {
      return strings.storySpentOnly(amount(story.spent));
    }
    return story.left.isNegative
        ? strings.storyMoreThanCameIn(amount(Money.zero - story.left))
        : strings.storyLeftOver(amount(story.left));
  }

  /// "Your 5 Saturdays came to ₹15,840."
  static String weekday(StoryWeekday line, AppLocalizations strings, AmountWriter amount) =>
      strings.storyWeekday(line.count, _weekdays[line.weekday - 1], amount(line.total));

  /// Page 5's headline: less than, more than, or the same as [previous].
  static String change(StoryComparison against, String previous, AppLocalizations strings, AmountWriter amount) {
    if (against.change.isZero) {
      return strings.storyChangeSame(previous);
    }
    return against.change.isNegative
        ? strings.storyChangeLess(amount(Money.zero - against.change), previous)
        : strings.storyChangeMore(amount(against.change), previous);
  }

  /// One category move: "₹3,900 less" or "₹1,200 more".
  static String move(CategoryMove move, AppLocalizations strings, AmountWriter amount) => move.change.isNegative
      ? strings.storyMoveLess(amount(Money.zero - move.change))
      : strings.storyMoveMore(amount(move.change));

  /// A day as page 4 names it, "Sat 12 Sep".
  static String day(CalendarDate date, String locale) => DateFormat('EEE d MMM', locale).format(DateTime(date.year, date.month, date.day));

  /// A short date, "4 Sep".
  static String shortDate(CalendarDate date, String locale) => DateFormat('d MMM', locale).format(DateTime(date.year, date.month, date.day));

  /// What the day bars paint for [days] of a cycle starting on [start].
  static DayBarsData bars(StoryDays days, CalendarDate start) => (
        perDay: days.perDay.map((Money m) => m.amountMinor).toList(),
        share: days.share.map((Money m) => m.amountMinor).toNullable(),
        marked: days.weekday
            .map((StoryWeekday w) => <int>{
                  for (final (int i, Money _) in days.perDay.indexed)
                    if (start.addDays(i).weekday == w.weekday) i,
                })
            .getOrElse(() => const <int>{}),
      );
}
