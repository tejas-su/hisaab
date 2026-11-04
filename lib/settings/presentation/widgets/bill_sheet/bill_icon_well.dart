import 'package:flutter/material.dart';

import '../../../../core/design/app_icon.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/design/hisaab_shapes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/design/app_icons.dart';

/// A bill's or saving's [glyph] in a 40dp `sunk` well (D118, D120). Decorative: the name is read beside it.
class BillIconWell extends StatelessWidget {
  const BillIconWell({super.key, required this.glyph});

  final AppIconData glyph;

  @override
  Widget build(BuildContext context) => Container(
        width: HisaabSizes.iconWell,
        height: HisaabSizes.iconWell,
        alignment: Alignment.center,
        decoration: ShapeDecoration(color: context.colors.sunk, shape: HisaabShapes.squircle(HisaabRadii.chip)),
        child: AppIcon(glyph, color: context.colors.displayInk),
      );
}
