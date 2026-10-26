import 'package:flutter/services.dart';

/// The app's haptic vocabulary (UI_DESIGN §7); one effect per user event, never buzzy.
abstract interface class Haptics {
  /// Keypad digit, chip, tile highlight (Android CLOCK_TICK).
  Future<void> tick();

  /// Entry saved, onboarding finished (Android CONFIRM).
  Future<void> success();

  /// Input rejected, e.g. a 10th digit (Android REJECT).
  Future<void> reject();

  /// A swipe crossed its delete threshold (Android VIRTUAL_KEY).
  Future<void> threshold();
}

/// [Haptics] backed by Flutter's platform haptic constants, which honour the system setting.
final class SystemHaptics implements Haptics {
  const SystemHaptics();

  @override
  Future<void> tick() => HapticFeedback.selectionClick();

  @override
  Future<void> success() => HapticFeedback.successNotification();

  @override
  Future<void> reject() => HapticFeedback.errorNotification();

  @override
  Future<void> threshold() => HapticFeedback.lightImpact();
}
