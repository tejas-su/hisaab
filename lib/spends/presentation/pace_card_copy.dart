import 'package:intl/intl.dart';

import '../../core/money/money.dart';
import '../../core/money/money_formatter.dart';
import '../../core/time/calendar_date.dart';
import '../../ledger/ledger.dart';
import '../../l10n/gen/app_localizations.dart';
import '../domain/entities/pace_series.dart';

/// The pace card's words: the line under the chart and what TalkBack reads (SPEC FR-SP-3, D133, D135).
final class PaceCardCopy {
  const PaceCardCopy(this._strings, this._money);

  final AppLocalizations _strings;
  final MoneyFormatter _money;

  /// A date as the chart shows it, e.g. "1 Nov".
  String date(CalendarDate day) => DateFormat('d MMM', _money.locale).format(DateTime(day.year, day.month, day.day));

  /// The line under the chart, e.g. "₹7,042 under steady pace. At this pace about ₹9,300 spare."; null
  /// unless [showToday] (the current cycle). It is TalkBack's gap and forecast with ₹ amounts (D135).
  String? line(PaceSeries series, {required bool showToday}) => showToday ? _gapAndForecast(series, _money.format) : null;

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
    return <String>[total, _gapAndForecast(series, _spokenAmount)].join(_strings.wordGap);
  }

  String _gapAndForecast(PaceSeries series, String Function(Money) amount) {
    final Money gap = series.gap;
    final String gapWords = gap > Money(0, currency: gap.currency) ? _strings.paceGapOver(amount(gap)) : _strings.paceGapUnder(amount(gap * -1));
    final String? forecast = switch (series.forecast.toNullable()) {
      LastsTillPayday(:final Money spare) => _strings.paceSpare(amount(spare)),
      RunsOut(date: final CalendarDate day) => _strings.paceRunsOut(date(day)),
      TooEarlyToForecast() || null => null,
    };
    return <String>[gapWords, ?forecast].join(_strings.wordGap);
  }

  String _spokenAmount(Money money) => _strings.spokenAmount(_money.digits(money));
}
