import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Motion tokens (UI_DESIGN §6): Apple-style springs, critically damped unless a gesture threw it.
abstract final class HisaabMotion {
  /// Key releases, chips, toggles (response 0.25 s, no overshoot).
  static final SpringDescription snap = spring(response: 0.25, damping: 1);

  /// Tray height changes, tabs, block drain, list inserts (0.35 s, no overshoot).
  static final SpringDescription standard = spring(response: 0.35, damping: 1);

  /// Only for a tray thrown by the user's finger (0.4 s, slight overshoot).
  static final SpringDescription flick = spring(response: 0.4, damping: 0.8);

  /// Onboarding blocks assembling, the morning "blocks grow" (0.55 s).
  static final SpringDescription calm = spring(response: 0.55, damping: 1);

  /// Key press feedback.
  static const Duration press = Duration(milliseconds: 120);

  /// Digits rolling to a new amount.
  static const Duration numberRoll = Duration(milliseconds: 300);

  /// The only transition used when the system asks for reduced motion.
  static const Duration reducedCrossfade = Duration(milliseconds: 150);

  /// Ease-out for entering elements; nothing enters with ease-in.
  static const Curve easeOut = Cubic(0.23, 1, 0.32, 1);

  /// Pressed keys and tiles scale to this.
  static const double pressedScale = 0.97;

  /// Converts Apple's response/damping description to a Flutter spring:
  /// stiffness = (2π / response)², mass 1.
  static SpringDescription spring({required double response, required double damping}) =>
      SpringDescription.withDampingRatio(
        mass: 1,
        stiffness: math.pow(2 * math.pi / response, 2).toDouble(),
        ratio: damping,
      );

  /// Whether the user asked the system for reduced motion; callers fall back to [reducedCrossfade].
  static bool reduceMotion(BuildContext context) => MediaQuery.disableAnimationsOf(context);
}
