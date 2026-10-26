import 'package:flutter/widgets.dart';

import '../design/hisaab_motion.dart';

/// Builds a control's look for its [pressed] state.
typedef PressableBuilder = Widget Function(BuildContext context, bool pressed);

/// A tappable surface that scales to 0.97 while pressed and announces itself as one button.
///
/// Use it for the app's own controls (keys, tiles, chips), which have no Material ripple. When
/// [onPressed] is null the control is disabled.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.semanticLabel,
    required this.onPressed,
    required this.builder,
    this.onLongPress,
    this.selected,
  });

  /// What a screen reader says; the child's own semantics are replaced.
  final String semanticLabel;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;

  /// Set for toggles and segments so the selected state is announced.
  final bool? selected;
  final PressableBuilder builder;

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
    );
  }
}
