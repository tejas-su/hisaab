import 'package:material_ui/material_ui.dart';

import '../../../../core/design/app_icon.dart';
import '../../../../core/design/app_icons.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/design/hisaab_shapes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/widgets/pressable.dart';

/// A full-width `sunk` key at the foot of the bill, in the place Save takes on a question:
/// used for *Delete bill* (SPEC FR-SE-1 AC-6).
class BillWideKey extends StatelessWidget {
  const BillWideKey({super.key, required this.label, required this.icon, required this.onPressed});

  final String label;
  final AppIconData icon;
  final VoidCallback onPressed;

  static const double _height = 56;

  @override
  Widget build(BuildContext context) => Pressable(
        semanticLabel: label,
        onPressed: onPressed,
        focusRadius: HisaabRadii.key,
        builder: (BuildContext context, bool pressed) => Container(
          constraints: const BoxConstraints(minHeight: _height),
          alignment: Alignment.center,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.l),
          decoration: ShapeDecoration(
            color: pressed ? context.colors.hairline : context.colors.sunk,
            shape: HisaabShapes.squircle(HisaabRadii.key),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              AppIcon(icon, size: 20),
              const SizedBox(width: HisaabSpacing.s),
              Flexible(child: Text(label, style: Theme.of(context).textTheme.titleMedium)),
            ],
          ),
        ),
      );
}
