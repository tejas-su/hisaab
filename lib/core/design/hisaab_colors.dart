import 'package:flutter/material.dart';

/// The app's colour tokens (UI_DESIGN §3.2): warm monochrome plus one marigold signal.
///
/// [signal] means "today / act" only and must never sit bare on [background] in light
/// theme (1.68:1); it always sits on [display]/[ink] or carries [onSignal] text.
@immutable
final class HisaabColors extends ThemeExtension<HisaabColors> {
  const HisaabColors({
    required this.background,
    required this.surface,
    required this.sunk,
    required this.hairline,
    required this.ink,
    required this.ink2,
    required this.signal,
    required this.onSignal,
    required this.display,
    required this.displayInk,
    required this.displayInk2,
    required this.blockIdle,
  });

  /// Light theme tokens.
  static const HisaabColors light = HisaabColors(
    background: Color(0xFFF6F5F1),
    surface: Color(0xFFFCFBF8),
    sunk: Color(0xFFECEAE4),
    hairline: Color(0xFFDAD8D1),
    ink: Color(0xFF161615),
    ink2: Color(0xFF62615C),
    signal: Color(0xFFFFB020),
    onSignal: Color(0xFF161615),
    display: Color(0xFF161615),
    displayInk: Color(0xFFF2F1EC),
    displayInk2: Color(0xFF9C9B95),
    blockIdle: Color(0xFF3A3A37),
  );

  /// Dark theme tokens, designed rather than inverted.
  static const HisaabColors dark = HisaabColors(
    background: Color(0xFF121211),
    surface: Color(0xFF1C1C1A),
    sunk: Color(0xFF262624),
    hairline: Color(0xFF2C2C29),
    ink: Color(0xFFF2F1EC),
    ink2: Color(0xFF9C9B95),
    signal: Color(0xFFFFB020),
    onSignal: Color(0xFF161615),
    display: Color(0xFF1C1C1A),
    displayInk: Color(0xFFF2F1EC),
    displayInk2: Color(0xFF9C9B95),
    blockIdle: Color(0xFF3A3A37),
  );

  final Color background;
  final Color surface;

  /// Pressed-in surfaces: keys, chips, icon wells.
  final Color sunk;
  final Color hairline;
  final Color ink;

  /// Secondary text.
  final Color ink2;

  /// Marigold: today's block, the Add key, the Next key.
  final Color signal;

  /// Text and icons drawn on [signal].
  final Color onSignal;

  /// The hero "display" card.
  final Color display;
  final Color displayInk;
  final Color displayInk2;

  /// Day blocks that are not today.
  final Color blockIdle;

  @override
  HisaabColors copyWith({
    Color? background,
    Color? surface,
    Color? sunk,
    Color? hairline,
    Color? ink,
    Color? ink2,
    Color? signal,
    Color? onSignal,
    Color? display,
    Color? displayInk,
    Color? displayInk2,
    Color? blockIdle,
  }) =>
      HisaabColors(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        sunk: sunk ?? this.sunk,
        hairline: hairline ?? this.hairline,
        ink: ink ?? this.ink,
        ink2: ink2 ?? this.ink2,
        signal: signal ?? this.signal,
        onSignal: onSignal ?? this.onSignal,
        display: display ?? this.display,
        displayInk: displayInk ?? this.displayInk,
        displayInk2: displayInk2 ?? this.displayInk2,
        blockIdle: blockIdle ?? this.blockIdle,
      );

  @override
  HisaabColors lerp(HisaabColors? other, double t) {
    if (other == null) {
      return this;
    }
    Color mix(Color a, Color b) => Color.lerp(a, b, t) ?? a;
    return HisaabColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      sunk: mix(sunk, other.sunk),
      hairline: mix(hairline, other.hairline),
      ink: mix(ink, other.ink),
      ink2: mix(ink2, other.ink2),
      signal: mix(signal, other.signal),
      onSignal: mix(onSignal, other.onSignal),
      display: mix(display, other.display),
      displayInk: mix(displayInk, other.displayInk),
      displayInk2: mix(displayInk2, other.displayInk2),
      blockIdle: mix(blockIdle, other.blockIdle),
    );
  }
}
