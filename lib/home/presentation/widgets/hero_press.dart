import 'package:flutter/widgets.dart';

import '../../../core/design/hisaab_motion.dart';

/// Makes the hero feel like a card in the hand: it sinks to [HisaabMotion.pressedScale] while a
/// finger is down, then [onTap] runs on release (D106).
///
/// Only the touch feel lives here; the hero's own [Semantics] carries its tap action and hint.
class HeroPress extends StatefulWidget {
  const HeroPress({super.key, required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<HeroPress> createState() => _HeroPressState();
}

class _HeroPressState extends State<HeroPress> {
  bool _pressed = false;

  void _setPressed(bool pressed) {
    if (pressed != _pressed) {
      setState(() => _pressed = pressed);
    }
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (TapDownDetails _) => _setPressed(true),
        onTapUp: (TapUpDetails _) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? HisaabMotion.pressedScale : 1,
          duration: HisaabMotion.reduceMotion(context) ? Duration.zero : HisaabMotion.press,
          curve: HisaabMotion.easeOut,
          child: widget.child,
        ),
      );
}
