import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';

/// One of the two equal-weight, full-width answer keys of the guard (SPEC FR-FX-4 AC-1): a 56dp
/// outlined key that is **not** marigold, so neither answer reads as the one to press.
class FixGuardKey extends StatelessWidget {
  const FixGuardKey({super.key, required this.label, required this.onPressed, this.semanticLabel});

  final String label;
  final VoidCallback onPressed;

  /// What a screen reader says when it differs from [label], such as an amount in words.
  final String? semanticLabel;

  static const double height = 56;

  @override
  Widget build(BuildContext context) => Pressable(
        semanticLabel: semanticLabel ?? label,
        onPressed: onPressed,
        focusRadius: HisaabRadii.key,
        builder: (BuildContext context, bool pressed) => Container(
          constraints: const BoxConstraints(minHeight: height),
          alignment: Alignment.center,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.l),
          decoration: ShapeDecoration(
            color: pressed ? context.colors.hairline : context.colors.clear,
            shape: HisaabShapes.squircle(HisaabRadii.key, side: BorderSide(color: context.colors.ink, width: 1.5)),
          ),
          child: Text(label, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium),
        ),
      );
}
