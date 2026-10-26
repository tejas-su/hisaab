import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';

import '../../core/money/money.dart';
import '../../core/money/money_formatter.dart';
import '../../core/time/calendar_date.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ledger/ledger.dart';

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
  factory HeroCopy.of(CycleSummary summary, {required AppLocalizations strings, required MoneyFormatter money}) {
    final DateFormat dayMonth = DateFormat('d MMM', money.locale);
    String date(CalendarDate day) => dayMonth.format(DateTime(day.year, day.month, day.day));
    String shown(Money amount) => money.format(amount);
    String spokenAmount(Money amount) => strings.spokenAmount(money.digits(amount));
    final bool over = summary.state is OverToday || summary.state is OverCycle;
    final Money hero = over || summary.safeToday.isNegative ? Money.zero : summary.safeToday;
    final String days = strings.daysToPayday(summary.daysLeft);
    final RangeWords spokenRange = _range(summary, strings, spokenAmount, date);
    return HeroCopy._(
      heroAmount: hero,
      muted: over,
      overText: _overText(summary.state, strings, shown),
      laterCaption: _laterCaption(summary, strings, shown).getOrElse(() => days),
      range: _range(summary, strings, shown, date),
      calm: summary.state is OnTrack && summary.forecast is! RunsOut,
      payday: date(summary.payday),
      spoken: strings.heroSpoken(
        strings.safeToSpendToday,
        spokenAmount(hero),
        _laterCaption(summary, strings, spokenAmount).getOrElse(() => days),
        _join(strings, spokenRange),
      ),
    );
  }

  /// Never below ₹0; ₹0 in the over states.
  final Money heroAmount;

  /// The hero number is shown quieter (`displayInk2`) when over.
  final bool muted;

  /// "₹220 over today" next to the ₹0, in the over states.
  final Option<String> overText;

  /// Right-hand caption under the blocks: days to payday, or each later day's share.
  final String laterCaption;
  final RangeWords range;

  /// True for the check glyph (on track); false for the alert glyph.
  final bool calm;

  /// The payday flag's date, e.g. "4 Nov".
  final String payday;
  final String spoken;

  static Option<String> _overText(CycleState state, AppLocalizations strings, String Function(Money) amount) =>
      switch (state) {
        OverToday(:final Money over) => Option<String>.of(strings.amountOverToday(amount(over))),
        OverCycle(:final Money over) => Option<String>.of(strings.amountOver(amount(over))),
        NoIncome() || SlowDown() || OnTrack() => const Option<String>.none(),
      };

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
  List<Object?> get props => <Object?>[heroAmount, muted, overText, laterCaption, range, calm, payday, spoken];
}
