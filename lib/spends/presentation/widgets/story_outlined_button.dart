import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/signal_key.dart';

/// The month story's quiet action, such as *Done*: the outlined twin of the [SignalKey] above it,
/// with the same height, corners, type and room below, so the pair reads as one set and only the
/// marigold says which acts (SPEC FR-SP-7 AC-8, UI_DESIGN §5.4, D210).
class StoryOutlinedButton extends StatelessWidget {
  const StoryOutlinedButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  /// The key's look, from [SignalKey], so the two never drift apart.
  static const double height = SignalKey.minHeight;

  @override
  Widget build(BuildContext context) => Pressable(
        semanticLabel: label,
        onPressed: onPressed,
        focusRadius: SignalKey.radius,
        builder: (BuildContext context, bool pressed) => Container(
          constraints: const BoxConstraints(minHeight: height),
          // why: the SignalKey keeps 2dp below it for its lip; the twin keeps the same footprint.
          margin: const EdgeInsetsDirectional.only(bottom: SignalKey.lip),
          alignment: Alignment.center,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.l, vertical: HisaabSpacing.s),
          decoration: ShapeDecoration(
            color: pressed ? context.colors.sunk : context.colors.clear,
            shape: HisaabShapes.squircle(SignalKey.radius, side: BorderSide(color: context.colors.hairline, width: 1.5)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: context.colors.ink, fontSize: SignalKey.labelSize),
          ),
        ),
      );
}
