import 'package:intl/intl.dart';

import '../../core/money/money.dart';
import '../../core/money/money_formatter.dart';
import '../../core/time/calendar_date.dart';
import '../../ledger/ledger.dart';
import '../../l10n/gen/app_localizations.dart';
import '../domain/entities/pace_series.dart';
import 'widgets/pace_chart_words.dart';

/// The pace card's words: what the chart paints and what TalkBack reads (SPEC FR-SP-3, D133).
final class PaceCardCopy {
  const PaceCardCopy(this._strings, this._money);

  final AppLocalizations _strings;
  final MoneyFormatter _money;

  /// A date as the chart shows it, e.g. "1 Nov".
  String date(CalendarDate day) => DateFormat('d MMM', _money.locale).format(DateTime(day.year, day.month, day.day));

  /// The gap and forecast words; the gap only when [showToday] (the current cycle).
  PaceChartWords chartWords(PaceSeries series, {required bool showToday}) => PaceChartWords(
        gap: showToday ? _gap(series.gap, _money.format, under: _strings.paceGapUnder, over: _strings.paceGapOver) : null,
        forecast: switch (series.forecast.toNullable()) {
          LastsTillPayday(:final Money spare) => _strings.aboutSpare(_money.format(spare)),
          RunsOut(date: final CalendarDate day) => _strings.paceRunsOut(date(day)),
          TooEarlyToForecast() || null => null,
        },
      );

  /// The card as one sentence: the total, the verdict, then on the current cycle the gap and the forecast.
  String spoken(Money spent, PaceSeries? series, {required bool showToday}) {
    if (series == null) {
      return _strings.spentSoFarSpoken(_spokenAmount(spent));
    }
    final String verdict = series.verdict == PaceVerdict.belowPace ? _strings.belowPace : _strings.abovePace;
    final String total = _strings.paceSpoken(_spokenAmount(spent), _spokenAmount(series.budget), verdict);
    if (!showToday) {
      return total;
    }
    final String gap = _gap(series.gap, _spokenAmount, under: _strings.paceGapUnderSpoken, over: _strings.paceGapOverSpoken);
    final String? forecast = switch (series.forecast.toNullable()) {
      LastsTillPayday(:final Money spare) => _strings.paceSpareSpoken(_spokenAmount(spare)),
      RunsOut(date: final CalendarDate day) => _strings.paceRunsOutSpoken(date(day)),
      TooEarlyToForecast() || null => null,
    };
    return <String>[total, gap, ?forecast].join(_strings.wordGap);
  }

  String _spokenAmount(Money money) => _strings.spokenAmount(_money.digits(money));

  static String _gap(
    Money gap,
    String Function(Money) amount, {
    required String Function(String) under,
    required String Function(String) over,
  }) =>
      gap > Money(0, currency: gap.currency) ? over(amount(gap)) : under(amount(gap * -1));
}
