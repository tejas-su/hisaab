import '../../../core/design/hisaab_type.dart';
import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/entities/pace_series.dart';
import 'pace_chart_painter.dart';
import 'spends_card.dart';

/// "Spent so far ₹27,570 of ₹45,000", the pace chart and its verdict (SPEC FR-SP-3).
///
/// Without [pace] (no money came in) only the total shows. TalkBack reads the card as one
/// sentence. [showToday] marks today on the current cycle.
class PaceCard extends StatelessWidget {
  const PaceCard({super.key, required this.spent, required this.pace, required this.showToday});

  final Money spent;
  final Option<PaceSeries> pace;
  final bool showToday;

  static const double _chartHeight = 132;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final PaceSeries? series = pace.toNullable();
    return SpendsCard(
      child: Semantics(
        container: true,
        label: _spoken(context, strings, series),
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _total(context, strings, series),
            if (series != null) ...<Widget>[
              const SizedBox(height: HisaabSpacing.s),
              SizedBox(height: _chartHeight, width: double.infinity, child: CustomPaint(painter: _painter(context, series))),
              const SizedBox(height: HisaabSpacing.s),
              _legend(context, strings, series.verdict),
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

  PaceChartPainter _painter(BuildContext context, PaceSeries series) => PaceChartPainter(
        series: series,
        axisLabels: series.axisLabels.map(context.money.compact).toList(),
        labelStyle: Theme.of(context).textTheme.labelSmall ?? const TextStyle(),
        ink: context.colors.ink,
        ink2: context.colors.ink2,
        hairline: context.colors.hairline,
        signal: context.colors.signal,
        showToday: showToday,
      );

  Widget _legend(BuildContext context, AppLocalizations strings, PaceVerdict verdict) {
    final TextStyle? caption = Theme.of(context).textTheme.bodySmall;
    final bool below = verdict == PaceVerdict.belowPace;
    return Wrap(
      spacing: HisaabSpacing.l,
      runSpacing: HisaabSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        _key(Container(width: 16, height: 2.5, color: context.colors.ink), Text(strings.paceYou, style: caption)),
        _key(
          SizedBox(width: 16, height: 2.5, child: CustomPaint(painter: _DotsPainter(context.colors.ink2))),
          Text(strings.paceSteady, style: caption),
        ),
        _key(
          AppIcon(below ? AppIcons.onTrack : AppIcons.alert, size: 16),
          Text(below ? strings.belowPace : strings.abovePace, style: HisaabType.emphasized(caption)?.copyWith(color: context.colors.ink)),
        ),
      ],
    );
  }

  static Widget _key(Widget mark, Widget label) =>
      Row(mainAxisSize: MainAxisSize.min, children: <Widget>[mark, const SizedBox(width: 6), label]);

  String _spoken(BuildContext context, AppLocalizations strings, PaceSeries? series) {
    String amount(Money money) => strings.spokenAmount(context.money.digits(money));
    if (series == null) {
      return strings.spentSoFarSpoken(amount(spent));
    }
    final String verdict = series.verdict == PaceVerdict.belowPace ? strings.belowPace : strings.abovePace;
    return strings.paceSpoken(amount(spent), amount(series.budget), verdict);
  }
}

/// The dotted "Steady pace" legend mark.
class _DotsPainter extends CustomPainter {
  const _DotsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dot = Paint()..color = color;
    for (double x = 1; x < size.width; x += 4) {
      canvas.drawCircle(Offset(x, size.height / 2), 1, dot);
    }
  }

  @override
  bool shouldRepaint(_DotsPainter oldDelegate) => oldDelegate.color != color;
}
