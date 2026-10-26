import 'package:flutter/material.dart';

import '../design/app_icon.dart';
import '../design/app_icons.dart';
import '../design/hisaab_dimensions.dart';
import '../design/hisaab_motion.dart';
import '../design/hisaab_shapes.dart';
import '../extensions/build_context_extensions.dart';
import 'pressable.dart';

/// The marigold "act" key with its 2dp ink lip, after the Braun ET66's "=" (UI_DESIGN §3.1).
///
/// The only tinted control: Add, Next and the onboarding finish. When [onPressed] is null it
/// turns grey, because marigold means "act" and a disabled key can't act.
class SignalKey extends StatelessWidget {
  const SignalKey({super.key, required this.label, required this.onPressed, this.icon, this.height = minHeight});

  /// The tallest default; keys grow with text but never shrink below this.
  static const double minHeight = 58;
  static const double _lip = 2;

  final String label;
  final AppIconData? icon;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null;
    final Color ink = enabled ? context.colors.onSignal : context.colors.ink2;
    final AppIconData? glyph = icon;
    return Pressable(
      semanticLabel: label,
      onPressed: onPressed,
      builder: (BuildContext context, bool pressed) {
        final double lip = enabled && !pressed ? _lip : 0;
        return AnimatedContainer(
          duration: HisaabMotion.reduceMotion(context) ? Duration.zero : HisaabMotion.press,
          curve: HisaabMotion.easeOut,
          constraints: BoxConstraints(minHeight: height),
          margin: EdgeInsetsDirectional.only(top: _lip - lip, bottom: lip),
          padding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.l, vertical: HisaabSpacing.s),
          decoration: ShapeDecoration(
            color: enabled ? context.colors.signal : context.colors.sunk,
            shape: HisaabShapes.squircle(18, side: BorderSide(color: enabled ? context.colors.onSignal : context.colors.hairline, width: 1.5)),
            shadows: <BoxShadow>[if (lip > 0) BoxShadow(color: context.colors.onSignal, offset: Offset(0, lip))],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (glyph != null) ...<Widget>[AppIcon(glyph, color: ink), const SizedBox(width: HisaabSpacing.s)],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: ink, fontSize: 21),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
