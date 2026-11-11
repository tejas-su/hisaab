import 'package:material_ui/material_ui.dart';

import '../design/hisaab_dimensions.dart';
import '../design/hisaab_shapes.dart';
import '../extensions/build_context_extensions.dart';
import 'pressable.dart';

/// One key of the [Keypad]: a `sunk` squircle that darkens and shrinks while pressed.
class KeypadKey extends StatelessWidget {
  const KeypadKey({
    super.key,
    required this.semanticLabel,
    required this.onPressed,
    required this.child,
    required this.height,
    this.onLongPress,
  });

  final String semanticLabel;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) => Pressable(
        semanticLabel: semanticLabel,
        onPressed: onPressed,
        onLongPress: onLongPress,
        focusRadius: HisaabRadii.key,
        builder: (BuildContext context, bool pressed) => Container(
          constraints: BoxConstraints(minHeight: height),
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: pressed ? context.colors.hairline : context.colors.sunk,
            shape: HisaabShapes.squircle(HisaabRadii.key),
          ),
          child: child,
        ),
      );
}
