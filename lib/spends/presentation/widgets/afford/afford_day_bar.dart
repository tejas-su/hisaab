import 'package:material_ui/material_ui.dart';

import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/design/hisaab_shapes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/money/money.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../afford_copy.dart';

/// One day-amount line under the answer: its label, a track with an ink outline ("usually") or
/// fill ("with this") and a tick at the breathing space [floor], and the amount (UI_DESIGN 5.4a).
/// Ink only: never marigold, red or green.
class AffordDayBar extends StatelessWidget {
  const AffordDayBar({super.key, required this.bar, required this.floor, required this.scale});

  final AffordBar bar;
  final Money floor;

  /// The amount a full track stands for, shared by the bars so they compare.
  final Money scale;

  static const double _trackHeight = 12;
  static const double _tickHeight = 22;
  static const double _tickWidth = 2;
  static const double _labelWidth = 88;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final String spoken = strings.affordBarSpoken(bar.label, strings.spokenAmount(context.money.digits(bar.perDay)));
    final TextTheme text = Theme.of(context).textTheme;
    return Semantics(
      label: spoken,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(vertical: HisaabSpacing.xs),
        child: Row(
          children: <Widget>[
            SizedBox(width: _labelWidth, child: Text(bar.label, style: text.bodyMedium)),
            Expanded(child: SizedBox(height: _tickHeight, child: _track(context))),
            const SizedBox(width: HisaabSpacing.s),
            Text(context.money.format(bar.perDay), style: text.titleMedium),
          ],
        ),
      ),
    );
  }

  Widget _track(BuildContext context) {
    final Color ink = context.colors.ink;
    return Stack(
      alignment: AlignmentDirectional.centerStart,
      children: <Widget>[
        FractionallySizedBox(
          widthFactor: _share(bar.perDay),
          child: Container(
            height: _trackHeight,
            decoration: ShapeDecoration(
              color: bar.filled ? ink : context.colors.clear,
              shape: HisaabShapes.squircle(HisaabRadii.block, side: BorderSide(color: ink, width: 1.5)),
            ),
          ),
        ),
        Align(
          alignment: AlignmentDirectional(2 * _share(floor) - 1, 0),
          child: Container(
            key: const ValueKey<String>('afford-floor-tick'),
            width: _tickWidth,
            height: _tickHeight,
            color: context.colors.ink2,
          ),
        ),
      ],
    );
  }

  // why: a sliver stays visible at ₹0 so an empty day reads as a line, not a gap.
  double _share(Money amount) => scale.isZero ? 0 : (amount.amountMinor / scale.amountMinor).clamp(0.02, 1.0);
}
