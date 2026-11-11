import 'package:material_ui/material_ui.dart';

import '../../../core/design/hisaab_dimensions.dart';
import '../../../core/design/hisaab_shapes.dart';
import '../../../core/extensions/build_context_extensions.dart';
import '../../../core/widgets/pressable.dart';

/// A full-width key in the restore dialog or on the *Delete everything* page.
///
/// [strong] fills it `inverse` with page-coloured text (*Replace*); otherwise it is a `hairline`
/// fill (*Keep what's here*, *Back up first*). Never marigold: these acts replace or remove data,
/// or lead up to that (UI_DESIGN §5.6).
class DialogKey extends StatelessWidget {
  const DialogKey({super.key, required this.label, required this.onPressed, this.strong = false, this.leading});

  final String label;
  final VoidCallback? onPressed;
  final bool strong;

  /// An optional glyph before the label.
  final Widget? leading;

  /// The key's height.
  static const double height = 56;

  @override
  Widget build(BuildContext context) {
    final Color foreground = strong ? context.colors.background : context.colors.ink;
    final Widget? glyph = leading;
    return Pressable(
      semanticLabel: label,
      onPressed: onPressed,
      focusRadius: HisaabRadii.key,
      builder: (BuildContext context, bool pressed) => Container(
        constraints: const BoxConstraints(minHeight: height),
        padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.l, vertical: HisaabSpacing.s),
        decoration: ShapeDecoration(
          color: strong ? context.colors.inverse : (pressed ? context.colors.sunk : context.colors.hairline),
          shape: HisaabShapes.squircle(HisaabRadii.key),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (glyph != null) ...<Widget>[glyph, const SizedBox(width: HisaabSpacing.s)],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: foreground),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
