import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';

/// The month story's quiet action: an outlined pill on the dark surface, such as *Done* (SPEC
/// FR-SP-7 AC-8, UI_DESIGN §5.4). [height] is never under the 48dp target.
class StoryOutlinedButton extends StatelessWidget {
  const StoryOutlinedButton({super.key, required this.label, required this.onPressed, this.height = _defaultHeight});

  final String label;
  final VoidCallback onPressed;
  final double height;

  static const double _defaultHeight = 52;

  @override
  Widget build(BuildContext context) => Pressable(
        semanticLabel: label,
        onPressed: onPressed,
        focusRadius: height / 2,
        builder: (BuildContext context, bool pressed) => Container(
          constraints: BoxConstraints(minHeight: height),
          alignment: Alignment.center,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.gutter),
          decoration: ShapeDecoration(
            color: pressed ? context.colors.sunk : context.colors.clear,
            shape: HisaabShapes.squircle(height / 2, side: BorderSide(color: context.colors.hairline, width: 1.5)),
          ),
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
      );
}
