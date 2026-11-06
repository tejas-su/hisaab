import 'package:flutter/material.dart';

import '../../../core/design/app_icon.dart';
import '../../../core/design/app_icons.dart';
import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/amount_text.dart';
import '../../../core/widgets/pressable.dart';

/// The title of the tray's later steps: a back well, the amount, and the step's [question]
/// under it (FR-AD-4, FR-AD-9).
class TrayStepTitle extends StatelessWidget {
  const TrayStepTitle({super.key, required this.amount, required this.question, required this.backLabel, required this.onBack});

  final Money amount;
  final String question;

  /// What TalkBack says for the back well.
  final String backLabel;
  final VoidCallback onBack;

  static const double _wellMargin = (HisaabSizes.minTouchTarget - HisaabSizes.iconWell) / 2;

  @override
  Widget build(BuildContext context) => Row(
        children: <Widget>[
          Pressable(
            key: const ValueKey<String>('back-to-amount'),
            semanticLabel: backLabel,
            onPressed: onBack,
            focusInset: const EdgeInsetsDirectional.only(top: _wellMargin, end: 2 * _wellMargin, bottom: _wellMargin),
            // why: same well as Home's Settings button, at the start so it lines up with the tiles.
            builder: (BuildContext context, bool pressed) => Container(
              width: HisaabSizes.minTouchTarget,
              height: HisaabSizes.minTouchTarget,
              alignment: AlignmentDirectional.centerStart,
              child: Container(
                key: const ValueKey<String>('back-to-amount-well'),
                width: HisaabSizes.iconWell,
                height: HisaabSizes.iconWell,
                alignment: Alignment.center,
                decoration: ShapeDecoration(color: context.colors.sunk, shape: HisaabShapes.squircle(HisaabRadii.chip)),
                child: const AppIcon(AppIcons.back),
              ),
            ),
          ),
          const SizedBox(width: HisaabSpacing.m),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                AmountText(amount, roll: false, style: Theme.of(context).textTheme.displaySmall),
                Text(question, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: context.colors.ink2)),
              ],
            ),
          ),
        ],
      );
}
