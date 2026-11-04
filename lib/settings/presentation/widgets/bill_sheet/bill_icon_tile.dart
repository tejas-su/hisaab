import 'package:flutter/material.dart';

import '../../../../core/design/app_icon.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/design/hisaab_shapes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/widgets/pressable.dart';
import '../../../../ledger/ledger.dart';
import 'bill_sheet_copy.dart';

/// One icon in the icon question's grid, labelled under its glyph; the bill's current icon
/// is [picked]: lifted to `control` with an `ink` dot, and announced as selected (D118).
class BillIconTile extends StatelessWidget {
  const BillIconTile({super.key, required this.icon, required this.picked, required this.onPressed});

  final BillIcon icon;
  final bool picked;
  final VoidCallback onPressed;

  static const double _minHeight = 68;
  static const double _dotSize = 6;
  static const double _dotInset = 6;

  @override
  Widget build(BuildContext context) {
    final String name = context.iconName(icon);
    return Pressable(
      semanticLabel: name,
      selected: picked,
      focusRadius: HisaabRadii.key,
      onPressed: onPressed,
      builder: (BuildContext context, bool pressed) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Container(
            constraints: const BoxConstraints(minHeight: _minHeight),
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 2, vertical: 6),
            alignment: Alignment.center,
            decoration: ShapeDecoration(
              color: _fill(context, pressed: pressed),
              shape: HisaabShapes.squircle(HisaabRadii.key),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AppIcon(icon.glyph, size: 22),
                const SizedBox(height: HisaabSpacing.xs),
                Text(name, textAlign: TextAlign.center, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.colors.ink)),
              ],
            ),
          ),
          if (picked)
            PositionedDirectional(
              top: _dotInset,
              end: _dotInset,
              child: Container(
                width: _dotSize,
                height: _dotSize,
                decoration: BoxDecoration(color: context.colors.ink, shape: BoxShape.circle),
              ),
            ),
        ],
      ),
    );
  }

  Color _fill(BuildContext context, {required bool pressed}) {
    if (pressed) {
      return context.colors.hairline;
    }
    return picked ? context.colors.control : context.colors.sunk;
  }
}
