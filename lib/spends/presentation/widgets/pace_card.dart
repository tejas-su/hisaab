import '../../../core/design/hisaab_type.dart';
import 'package:material_ui/material_ui.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/layout/window_class.dart';
import '../../../core/money/money.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/pace_series.dart';
import '../pace_card_copy.dart';
import 'pace_chart_painter.dart';
import 'pace_dates.dart';
import 'pace_legend.dart';
import 'spends_card.dart';

/// "Spent so far ₹27,570 of ₹45,000", the pace chart with its dates, and the key (SPEC FR-SP-3).
///
/// Without [pace] (no money came in) only the total shows. TalkBack reads the card as one
/// sentence. [showToday] marks today on the current cycle, with the gap to the steady line and the
/// forecast, said in a line under the key (D133, D135). [cycle] names the first and last days
/// under the chart.
class PaceCard extends StatelessWidget {
  const PaceCard({super.key, required this.spent, required this.pace, required this.cycle, required this.showToday});

  final Money spent;
  final Option<PaceSeries> pace;
  final PayCycle cycle;
  final bool showToday;

  static const double _chartHeightShare = 0.6;
  static const double _chartMinHeight = 168;
  static const double _chartMaxHeight = 216;
  static const double _chartShortWindowHeight = 160;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final PaceCardCopy copy = PaceCardCopy(strings, context.money);
    final PaceSeries? series = pace.toNullable();
    return SpendsCard(
      child: Semantics(
        container: true,
        label: copy.spoken(spent, series, showToday: showToday),
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _total(context, strings, series),
            if (series != null) ...<Widget>[
              const SizedBox(height: HisaabSpacing.m),
              _chart(context, series),
              const SizedBox(height: HisaabSpacing.xs),
              _dates(context, copy, strings, series),
              const SizedBox(height: HisaabSpacing.l),
              PaceLegend(
                verdict: series.verdict,
                showForecast: series.forecastByDay.isNotEmpty,
                line: copy.line(series, showToday: showToday),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _total(BuildContext context, AppLocalizations strings, PaceSeries? series) {
    final TextTheme text = Theme.of(context).textTheme;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: HisaabSpacing.m,
      children: <Widget>[
        Text(strings.spentSoFar, style: HisaabType.regular(text.titleMedium)?.copyWith(color: context.colors.ink2)),
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(text: context.money.format(spent), style: text.titleLarge?.copyWith(fontFeatures: const <FontFeature>[FontFeature.tabularFigures()])),
              if (series != null) TextSpan(text: '${strings.wordGap}${strings.ofAmount(context.money.format(series.budget))}', style: text.bodyMedium?.copyWith(color: context.colors.ink2)),
            ],
          ),
        ),
      ],
    );
  }

  // why: 0.6 of the width steepens the slope near today on a phone in portrait; the floor keeps a
  // ₹3,000 gap visible as a bracket, the cap keeps "Where it went" on a phone's first screen, and a
  // short window (a phone on its side) keeps the plot low so the page still has room (D135).
  Widget _chart(BuildContext context, PaceSeries series) => LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) => SizedBox(
          key: const ValueKey<String>('pace-chart'),
          height: _chartHeight(context, constraints.maxWidth),
          width: double.infinity,
          child: CustomPaint(painter: _painter(context, series)),
        ),
      );

  static double _chartHeight(BuildContext context, double width) => context.layout.heightClass == HeightClass.compact
      ? _chartShortWindowHeight
      : (width * _chartHeightShare).clamp(_chartMinHeight, _chartMaxHeight);

  PaceChartPainter _painter(BuildContext context, PaceSeries series) => PaceChartPainter(
        series: series,
        axisLabels: _axisLabels(context, series),
        labelStyle: _labelStyle(context),
        textScaler: MediaQuery.textScalerOf(context),
        colors: (
          ink: context.colors.ink,
          ink2: context.colors.ink2,
          hairline: context.colors.hairline,
          signal: context.colors.signal,
          surface: context.colors.surface,
        ),
        showToday: showToday,
      );

  Widget _dates(BuildContext context, PaceCardCopy copy, AppLocalizations strings, PaceSeries series) => PaceDates(
        start: copy.date(cycle.start),
        end: copy.date(cycle.end),
        today: strings.paceToday,
        todayAt: showToday ? series.spentByDay.length / series.cycleDays : null,
        labelStyle: _labelStyle(context).copyWith(color: context.colors.ink2),
        todayStyle: _markStyle(context),
      );

  static List<String> _axisLabels(BuildContext context, PaceSeries series) => series.axisLabels.map(context.money.compact).toList();

  static TextStyle _labelStyle(BuildContext context) => Theme.of(context).textTheme.labelSmall ?? const TextStyle();

  static TextStyle _markStyle(BuildContext context) =>
      (HisaabType.emphasized(Theme.of(context).textTheme.labelSmall) ?? const TextStyle()).copyWith(color: context.colors.ink);
}
