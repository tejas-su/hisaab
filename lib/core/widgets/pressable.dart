import 'package:flutter/widgets.dart';

import '../design/hisaab_dimensions.dart';
import '../design/hisaab_motion.dart';
import 'focus_ring.dart';

/// Builds a control's look for its [pressed] state.
typedef PressableBuilder = Widget Function(BuildContext context, bool pressed);

/// A tappable surface that scales to 0.97 while pressed and announces itself as one button.
///
/// Use it for the app's own controls (keys, tiles, chips), which have no Material ripple. When
/// [onPressed] is null the control is disabled.
///
/// It is focusable by keyboard, D-pad and switch access: Enter, Space and D-pad centre run
/// [onPressed], and focus draws a [FocusRing] that follows [focusRadius] and [focusInset]
/// (UI_DESIGN §9, D99). A disabled control is skipped.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.semanticLabel,
    required this.onPressed,
    required this.builder,
    this.onLongPress,
    this.selected,
    this.focusRadius = HisaabRadii.chip,
    this.focusInset = EdgeInsets.zero,
  });

  /// What a screen reader says; the child's own semantics are replaced.
  final String semanticLabel;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  /// Set for toggles and segments so the selected state is announced.
  final bool? selected;
  final PressableBuilder builder;

  /// The control's corner radius, which the focus ring follows.
  final double focusRadius;

  /// Moves the focus ring in from the control's bounds: to the visible well when it is smaller
  /// than the tap target, or inside a row that sits in a clipping card (see [FocusRing.inset]).
  final EdgeInsetsGeometry focusInset;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool pressed) {
    if (_enabled && pressed != _pressed) {
      setState(() => _pressed = pressed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = HisaabMotion.reduceMotion(context);
    return Semantics(
      button: true,
      enabled: _enabled,
      selected: widget.selected,
      label: widget.semanticLabel,
      onTap: widget.onPressed,
      onLongPress: widget.onLongPress,
      excludeSemantics: true,
      child: FocusRing(
        radius: widget.focusRadius,
        inset: widget.focusInset,
        child: FocusableActionDetector(
          enabled: _enabled,
          includeFocusSemantics: false,
          actions: <Type, Action<Intent>>{ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: _activate)},
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (TapDownDetails _) => _setPressed(true),
            onTapUp: (TapUpDetails _) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            onTap: widget.onPressed,
            onLongPress: widget.onLongPress,
            child: AnimatedScale(
              scale: _pressed ? HisaabMotion.pressedScale : 1,
              duration: reduceMotion ? Duration.zero : HisaabMotion.press,
              curve: HisaabMotion.easeOut,
              child: widget.builder(context, _pressed),
            ),
          ),
        ),
      ),
    );
  }

  // why: Enter, Space and D-pad centre map to ActivateIntent in WidgetsApp's default shortcuts.
  Object? _activate(ActivateIntent _) {
    widget.onPressed?.call();
    return null;
  }
}
