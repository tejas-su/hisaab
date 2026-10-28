import 'package:flutter/material.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/design/hisaab_type.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../domain/ask_goal.dart';

/// *This month* | *Last 3 months* as one segmented control (FR-AI-2), in the Spent | Got style:
/// equal segments on a `sunk` track, the pick raised as a near-white pill in light and an ink
/// pill in dark (Apple HIG segmented controls, D47, D67).
class PeriodSwitch extends StatelessWidget {
  const PeriodSwitch({super.key, required this.period, required this.onChanged});

  final AskPeriod period;
  final ValueChanged<AskPeriod> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('period-track'),
    padding: const EdgeInsetsDirectional.all(HisaabSpacing.xs),
    decoration: ShapeDecoration(color: context.colors.sunk, shape: HisaabShapes.squircle(HisaabRadii.key)),
    child: Row(
      spacing: HisaabSpacing.xs,
      children: <Widget>[for (final AskPeriod value in AskPeriod.values) Expanded(child: _segment(context, value))],
    ),
  );

  Widget _segment(BuildContext context, AskPeriod value) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final bool selected = value == period;
    // why: light layers alternate (D45, D47), so the pick rises out of the sunk track as a light
    // pill; in dark, where surface is darker than sunk, it stays an ink pill.
    final bool light = Theme.of(context).brightness == Brightness.light;
    final String label = switch (value) {
      AskPeriod.thisCycle => strings.askPeriodThis,
      AskPeriod.lastThreeCycles => strings.askPeriodThree,
    };
    return Pressable(
      semanticLabel: label,
      selected: selected,
      onPressed: () => onChanged(value),
      builder: (BuildContext context, bool pressed) => Container(
        key: ValueKey<String>('period-${value.name}'),
        constraints: const BoxConstraints(minHeight: HisaabSizes.minTouchTarget),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.s, vertical: HisaabSpacing.xs),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: selected ? (light ? context.colors.surface : context.colors.ink) : null,
          shape: HisaabShapes.squircle(HisaabRadii.chip),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          // why: one weight step marks the pick; the other segment is Regular and steps back by
          // colour (case study 02).
          style: selected
              ? HisaabType.emphasized(Theme.of(context).textTheme.bodyMedium)
                    ?.copyWith(color: light ? context.colors.ink : context.colors.background)
              : Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.colors.ink2),
        ),
      ),
    );
  }
}
