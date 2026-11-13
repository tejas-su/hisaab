import 'package:fpdart/fpdart.dart';

import '../../core/money/money.dart';
import '../../core/money/money_formatter.dart';
import '../../core/widgets/days_rail/days_rail_data.dart';
import '../../core/widgets/today_bar/today_bar_data.dart';
import '../../home/home.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../ledger/ledger.dart';
import '../../settings/settings.dart';
import '../domain/entities/projected_day.dart';
import '../domain/entities/widget_snapshot.dart';

/// Words and formats each projected day for the widget with Home's own copy and mappers, so the
/// widget says exactly what the hero says on that day (SPEC FR-WG-1, FR-WG-3, FR-WG-8).
abstract final class WidgetSnapshotMapper {
  /// The snapshot for [days], drawn in [look]; [writtenAt] is now.
  static WidgetSnapshot of(
    List<ProjectedDay> days, {
    required ThemeChoice look,
    required DateTime writtenAt,
    required WidgetWords words,
  }) =>
      WidgetSnapshot(
        writtenAt: writtenAt,
        look: look,
        strings: WidgetStrings(
          title: words.strings.safeToSpendToday,
          add: words.strings.add,
          addSpoken: words.strings.widgetAddSpoken,
          setUp: words.strings.widgetSetUp,
          setUpBody: words.strings.widgetSetUpBody,
        ),
        rows: days.map((ProjectedDay day) => _day(day, words)).toList(),
      );

  static WidgetDay _day(ProjectedDay day, WidgetWords words) {
    final CycleSummary summary = day.summary;
    final AppLocalizations strings = words.strings;
    final HeroCopy copy = HeroCopy.of(summary, strings: strings, money: words.money);
    final String? detail = copy.range.detail;
    return WidgetDay(
      date: summary.today,
      state: _state(summary.state),
      hero: words.money.format(copy.heroAmount),
      heroMuted: copy.muted,
      over: copy.overText,
      glance: _glance(summary.state, copy, words),
      range: detail == null ? copy.range.lead : '${copy.range.lead}${strings.separator}$detail',
      days: strings.widgetDays(summary.daysLeft),
      daysLeft: strings.widgetDaysLeft(summary.daysLeft),
      flag: copy.payday,
      bar: _bar(TodayBarMapper.of(summary, day.spends, nameOf: (Entry _) => '')),
      dots: _dots(DaysRailMapper.of(summary)),
      spoken: copy.spoken,
    );
  }

  // why: the 2×1 has no range line, so over the cycle it says "Over by ₹3,200" rather than the
  // hero's shorter "₹3,200 over" (widget spec §15 #4).
  static String _glance(CycleState state, HeroCopy copy, WidgetWords words) => switch (state) {
        OverCycle(:final Money over) => words.strings.overBy(words.money.format(over)),
        OverToday() => copy.overText.getOrElse(() => words.strings.widgetLeftToday),
        NoIncome() || SlowDown() || OnTrack() => words.strings.widgetLeftToday,
      };

  static WidgetDayState _state(CycleState state) => switch (state) {
        OnTrack() => WidgetDayState.onTrack,
        SlowDown() => WidgetDayState.slowDown,
        OverToday() => WidgetDayState.overToday,
        OverCycle() => WidgetDayState.overCycle,
        NoIncome() => WidgetDayState.setUp,
      };

  static WidgetBar _bar(TodayBarData data) => WidgetBar(
        style: switch (data.style) {
          TodayBarStyle.onTrack => WidgetBarStyle.onTrack,
          TodayBarStyle.slowDown => WidgetBarStyle.slowDown,
          TodayBarStyle.over => WidgetBarStyle.over,
        },
        left: data.left,
        bites: data.bites.map((TodayBite bite) => bite.share).toList(),
        tick: Option<double>.fromNullable(data.tick),
      );

  static WidgetDots _dots(DaysRailData data) => WidgetDots(
        count: data.count,
        style: switch (data.style) {
          DaysRailStyle.onTrack => WidgetDotsStyle.onTrack,
          DaysRailStyle.slowDown => WidgetDotsStyle.slowDown,
          DaysRailStyle.overToday => WidgetDotsStyle.overToday,
          DaysRailStyle.overCycle => WidgetDotsStyle.overCycle,
        },
      );
}

/// The words and amount format the widget is written in.
typedef WidgetWords = ({AppLocalizations strings, MoneyFormatter money});
