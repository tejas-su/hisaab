import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';

import '../../core/money/money.dart';
import '../../core/money/money_formatter.dart';
import '../../core/time/calendar_date.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ledger/ledger.dart';
import 'week_copy.dart';

/// One line of words under the blocks: a [lead] and an optional quieter [detail].
final class RangeWords extends Equatable {
  const RangeWords(this.lead, [this.detail]);

  final String lead;
  final String? detail;

  @override
  List<Object?> get props => <Object?>[lead, detail];
}

/// Every word the hero card shows for a [CycleSummary] (SPEC BR-5, BR-7; UI_DESIGN §3.3).
///
/// Each state carries words and a glyph, never colour alone. [spoken] is the one sentence
/// TalkBack reads for the whole card (FR-HO-7).
final class HeroCopy extends Equatable {
  const HeroCopy._({
    required this.title,
    required this.heroAmount,
    required this.muted,
    required this.overText,
    required this.laterCaption,
    required this.range,
    required this.calm,
    required this.payday,
    required this.spoken,
  });

  /// Builds the copy for [summary] in [strings], formatting amounts with [money].
  ///
  /// With [week] the number is *This week*'s (FR-HO-2), and the range slot and spoken days say how
  /// each day of the week went (BR-6a).
  factory HeroCopy.of(
    CycleSummary summary, {
    required AppLocalizations strings,
    required MoneyFormatter money,
    bool week = false,
  }) {
    final DateFormat dayMonth = DateFormat('d MMM', money.locale);
    String date(CalendarDate day) => dayMonth.format(DateTime(day.year, day.month, day.day));
    String shown(Money amount) => money.format(amount);
    String spokenAmount(Money amount) => strings.spokenAmount(money.digits(amount));
    final _Headline headline = week ? _Headline.week(summary, strings) : _Headline.today(summary, strings);
    final String days = strings.daysToPayday(summary.daysLeft);
    final String laterSpoken = _laterCaption(summary, strings, spokenAmount).getOrElse(() => days);
    final WeekCopy weekShown = WeekCopy(summary, strings: strings, amount: shown, locale: money.locale);
    final WeekCopy weekSpoken = WeekCopy(summary, strings: strings, amount: spokenAmount, locale: money.locale);
    return HeroCopy._(
      title: headline.title,
      heroAmount: headline.amount,
      muted: headline.muted,
      overText: headline.overText(shown),
      laterCaption: _laterCaption(summary, strings, shown).getOrElse(() => days),
      range: week ? weekShown.range : _range(summary, strings, shown, date),
      calm: week ? weekShown.calm : summary.state is OnTrack && summary.forecast is! RunsOut,
      payday: date(summary.payday),
      spoken: strings.heroSpoken(
        headline.title,
        spokenAmount(headline.amount),
        week ? weekSpoken.spokenDays ?? laterSpoken : laterSpoken,
        _join(strings, week ? weekSpoken.range : _range(summary, strings, spokenAmount, date)),
      ),
    );
  }

  /// "Safe to spend today" or "Safe to spend this week".
  final String title;

  /// Never below ₹0; ₹0 in the over states.
  final Money heroAmount;

  /// The hero number is shown quieter (`displayInk2`) when over.
  final bool muted;

  /// "₹220 over today" (or "over this week") next to the ₹0, in the over states.
  final Option<String> overText;

  /// Right-hand caption under the blocks: days to payday, or each later day's share.
  final String laterCaption;
  final RangeWords range;

  /// True for the check glyph (on track); false for the alert glyph.
  final bool calm;

  /// The payday flag's date, e.g. "4 Nov".
  final String payday;
  final String spoken;


  static Option<String> _laterCaption(CycleSummary summary, AppLocalizations strings, String Function(Money) amount) =>
      summary.state is OverToday
          ? summary.tomorrowShare.map((Money share) => strings.eachDayAfter(amount(share)))
          : const Option<String>.none();

  static RangeWords _range(
    CycleSummary summary,
    AppLocalizations strings,
    String Function(Money) amount,
    String Function(CalendarDate) date,
  ) {
    final RangeForecast forecast = summary.forecast;
    final String? runsOut = forecast is RunsOut ? strings.runsOutOnLower(date(forecast.date)) : null;
    return switch (summary.state) {
      OverCycle(:final Money over) => RangeWords(strings.overBy(amount(over)), strings.paydayIn(summary.daysLeft)),
      OverToday() => RangeWords(strings.overToday, runsOut ?? strings.stillLasts),
      SlowDown() => RangeWords(strings.slowDown, runsOut ?? strings.shareAlmostUsed),
      NoIncome() || OnTrack() => switch (forecast) {
          LastsTillPayday(:final Money spare) => RangeWords(strings.lastsTillPayday, strings.aboutSpare(amount(spare))),
          RunsOut(date: final CalendarDate day) => RangeWords(strings.runsOutOn(date(day))),
          TooEarlyToForecast() => RangeWords(strings.lastsTillPayday),
        },
    };
  }

  static String _join(AppLocalizations strings, RangeWords words) {
    final String? detail = words.detail;
    return detail == null ? words.lead : strings.spokenPair(words.lead, detail);
  }

  @override
  List<Object?> get props => <Object?>[title, heroAmount, muted, overText, laterCaption, range, calm, payday, spoken];
}

/// The title, number and overspend words for *Today* or *This week*.
final class _Headline {
  const _Headline({required this.title, required this.amount, required this.muted, this.over = const Option<_Over>.none()});

  factory _Headline.today(CycleSummary summary, AppLocalizations strings) {
    final Option<_Over> over = switch (summary.state) {
      OverToday(:final Money over) => Option<_Over>.of((over, strings.amountOverToday)),
      OverCycle(:final Money over) => Option<_Over>.of((over, strings.amountOver)),
      NoIncome() || SlowDown() || OnTrack() => const Option<_Over>.none(),
    };
    return _Headline(
      title: strings.safeToSpendToday,
      amount: over.isSome() || summary.safeToday.isNegative ? Money.zero : summary.safeToday,
      muted: over.isSome(),
      over: over,
    );
  }

  factory _Headline.week(CycleSummary summary, AppLocalizations strings) {
    final Money left = summary.safeThisWeek;
    return _Headline(
      title: strings.safeToSpendThisWeek,
      amount: left.isNegative ? Money.zero : left,
      muted: left.isNegative || left.isZero,
      over: left.isNegative ? Option<_Over>.of((Money.zero - left, strings.amountOverThisWeek)) : const Option<_Over>.none(),
    );
  }

  final String title;
  final Money amount;
  final bool muted;
  final Option<_Over> over;

  Option<String> overText(String Function(Money) shown) =>
      over.map(((Money, String Function(String)) over) => over.$2(shown(over.$1)));
}

/// How far over, and the words that say it.
typedef _Over = (Money, String Function(String));
