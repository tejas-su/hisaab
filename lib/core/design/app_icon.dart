import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

import 'app_icons.dart';
import 'hisaab_dimensions.dart';

/// Draws an [AppIcons] glyph at the app's stroke weight, coloured from [IconTheme] by default.
///
/// Pass [semanticLabel] when the icon carries meaning with no visible text next to it;
/// otherwise it is excluded from the semantics tree.
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size = HisaabSizes.iconSize, this.color, this.semanticLabel});

  final AppIconData icon;
  final double size;

  /// Overrides the inherited [IconTheme] colour.
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget glyph = HugeIcon(
      icon: icon,
      size: size,
      strokeWidth: HisaabSizes.iconStroke,
      color: color ?? IconTheme.of(context).color,
    );
    final String? label = semanticLabel;
    if (label == null) {
      return ExcludeSemantics(child: glyph);
    }
    return Semantics(label: label, image: true, child: ExcludeSemantics(child: glyph));
  }
}
