import 'package:material_ui/material_ui.dart';

import '../../../../core/design/app_icon.dart';
import '../../../../core/design/app_icons.dart';
import '../../../../core/design/hisaab_dimensions.dart';
import '../../../../core/design/hisaab_shapes.dart';
import '../../../../core/extensions/build_context_extensions.dart';
import '../../../../core/widgets/pressable.dart';

/// A full-width key on the bill: `sunk` for *Delete bill* (SPEC FR-SE-1 AC-6), or [outlined]
/// with an ink edge for *Used some of it* (AC-Y5). [semanticHint] is read after the label.
class BillWideKey extends StatelessWidget {
  const BillWideKey({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.outlined = false,
    this.semanticHint,
  });

  final String label;
  final AppIconData icon;
  final VoidCallback onPressed;
  final bool outlined;
  final String? semanticHint;

  static const double _height = 56;

  @override
  Widget build(BuildContext context) => Pressable(
        semanticLabel: label,
        semanticHint: semanticHint,
        onPressed: onPressed,
        focusRadius: HisaabRadii.key,
        builder: (BuildContext context, bool pressed) => Container(
          constraints: const BoxConstraints(minHeight: _height),
          alignment: Alignment.center,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.l),
          decoration: ShapeDecoration(
            color: pressed ? context.colors.hairline : (outlined ? context.colors.clear : context.colors.sunk),
            shape: HisaabShapes.squircle(
              HisaabRadii.key,
              side: outlined ? BorderSide(color: context.colors.ink, width: 1.5) : BorderSide.none,
            ),
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
