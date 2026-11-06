import 'package:flutter/material.dart';

/// The app's colour tokens (UI_DESIGN §3.2): warm monochrome plus one marigold signal, and one
/// [danger] red kept for the act that wipes everything.
///
/// [signal] means "today / act" only and must never sit bare on a light surface (about
/// 1.6:1); in light theme it always carries an [ink]/[displayEdge] edge or [onSignal] text.
@immutable
final class HisaabColors extends ThemeExtension<HisaabColors> {
  const HisaabColors({
    required this.background,
    required this.surface,
    required this.sunk,
    required this.hairline,
    required this.control,
    required this.ink,
    required this.ink2,
    required this.signal,
    required this.onSignal,
    required this.display,
    required this.displayInk,
    required this.displayInk2,
    required this.blockIdle,
    required this.displayEdge,
    required this.displayEtch,
    required this.displayShadow,
    required this.displaySheen,
    required this.inverse,
    required this.danger,
    required this.scrim,
    required this.clear,
    required this.focus,
    required this.focusGap,
  });

  // why: an alias names the same constant as the token it equals, so the two can't drift apart
  // (principle 27, D97). Only values that more than one token uses get a name here.
  static const Color _lightBackground = Color(0xFFF1EBE4);
  static const Color _lightSurface = Color(0xFFFFFEFC);
  static const Color _lightHairline = Color(0xFFD7CFC5);
  static const Color _lightInk = Color(0xFF161615);
  static const Color _darkBackground = Color(0xFF131210);
  static const Color _darkSurface = Color(0xFF211F1C);
  static const Color _darkSunk = Color(0xFF2F2B27);
  static const Color _darkHairline = Color(0xFF3A3632);
  static const Color _darkInk = Color(0xFFF2F1EC);
  static const Color _darkInk2 = Color(0xFFA7A199);

  /// Light theme tokens.
  static const HisaabColors light = HisaabColors(
    background: _lightBackground,
    surface: _lightSurface,
    sunk: Color(0xFFE7E0D8),
    hairline: _lightHairline,
    control: _lightSurface,
    ink: _lightInk,
    ink2: Color(0xFF5B5650),
    signal: Color(0xFFFFB020),
    onSignal: Color(0xFF161615),
    display: _lightSurface,
    displayInk: _lightInk,
    displayInk2: Color(0xFF65605A),
    blockIdle: _lightHairline,
    displayEdge: _lightInk,
    displayEtch: _lightBackground,
    displayShadow: Color(0x2E161615),
    displaySheen: Color(0xB3FFFEFC),
    // why: a charcoal, not ink, so a short-lived bar reads as dark without being a black slab (D105).
    inverse: Color(0xFF312E29),
    danger: Color(0xFFB42318),
    scrim: Color(0x52161615),
    clear: Color(0x00F1EBE4),
    focus: _lightInk,
    focusGap: _lightBackground,
  );

  /// Dark theme tokens, designed rather than inverted: each layer steps lighter by about the
  /// same contrast as its light counterpart (D92).
  static const HisaabColors dark = HisaabColors(
    background: _darkBackground,
    surface: _darkSurface,
    sunk: _darkSunk,
    hairline: _darkHairline,
    control: _darkHairline,
    ink: _darkInk,
    ink2: _darkInk2,
    signal: Color(0xFFFFB020),
    onSignal: Color(0xFF161615),
    display: _darkSurface,
    displayInk: _darkInk,
    displayInk2: _darkInk2,
    blockIdle: Color(0xFF413D38),
    displayEdge: Color(0x00000000),
    displayEtch: _darkSunk,
    // why: in dark the card already has a hairline edge; a shadow on a near-black page is invisible.
    displayShadow: Color(0x00000000),
    displaySheen: Color(0x1AF2F1EC),
    inverse: _darkInk,
    // why: lighter than the light red so it keeps ≥ 4.5:1 on the dark page, and page-dark text on it.
    danger: Color(0xFFF97066),
    // why: a light scrim on a dark page lifts it above the tray, inverting the layers (D93).
    scrim: Color(0x66000000),
    clear: Color(0x00131210),
    focus: _darkInk,
    focusGap: _darkBackground,
  );

  /// The page, the lowest layer.
  final Color background;

  /// Cards, sheets, the tray and the dock: one layer above [background].
  final Color surface;

  /// Keys and icon wells at rest: pressed in, so darker than [surface] in light, lighter in dark.
  final Color sunk;

  /// Dividers, the dock edge, the pressed fill of a [sunk] key, and the fill of a chip or field
  /// that sits on [surface] (the Add tray, a sheet, a card), where a [control] fill would vanish
  /// in light (D100).
  final Color hairline;

  /// Chips, the Back well and text fields at rest on the page: one layer up, like the cards.
  /// An alias of [surface] in light and of [hairline] in dark (D100).
  ///
  /// Only for controls on [background]; a control on [surface] uses [hairline] instead. Pressed,
  /// it steps to [sunk].
  final Color control;

  /// Primary text and icons, the ink fill of a flashed tile and of a picked chip, and a focused
  /// field's edge (D100).
  final Color ink;

  /// Secondary text, labels and hints; ≥ 4.5:1 on every fill.
  final Color ink2;

  /// Marigold: today's block, the Add key, the Next key.
  final Color signal;

  /// Text and icons drawn on [signal].
  final Color onSignal;

  /// The hero "display" card. An alias of [surface] in both themes: kept as its own token so the
  /// hero can change layer without touching every card (D97).
  final Color display;

  /// The hero's main text. An alias of [ink] in both themes (D97).
  final Color displayInk;

  /// The hero's secondary text and the over-state hatch. Its own grey (#62615C) in light, which
  /// stayed put when [ink2] darkened (D90); an alias of [ink2] in dark (D97).
  final Color displayInk2;

  /// Day blocks that are not today. An alias of [hairline] in light; its own step in dark, between
  /// [hairline] and [ink2], so idle days stay ≥ 1.5:1 on the card (D92, D97).
  final Color blockIdle;

  /// The edge around today's marigold block, so marigold never sits bare on a light card: an
  /// alias of [ink] in light; transparent where the card is dark.
  final Color displayEdge;

  /// The hero's guilloché etch and grain: an alias of [background] in light and of [sunk] in dark,
  /// under 1.2:1 on [display] so it never competes with the amount (D106).
  final Color displayEtch;

  /// The soft shadow that makes the hero the only raised card on Home: ink at 18% in light;
  /// transparent in dark, where the card keeps its hairline edge (D106).
  final Color displayShadow;

  /// The band of light that crosses the hero once when it appears and on each new day: the card
  /// colour at 70% in light, a wash; ink at 10% in dark, a lift (D106).
  final Color displaySheen;

  /// The snackbar's fill, the opposite of the page so it stands off any card: a warm charcoal
  /// in light, an alias of [ink] in dark. Text on it is [background] (D105).
  final Color inverse;

  /// The one destructive act, *Delete everything*: the hold key's edge, glyph and label at rest,
  /// and its fill, with [background] text on it. Nothing else is red; state is never red (D142).
  final Color danger;

  /// Dims the page under a tray, sheet or dialog: ink at 32% in light, black at 40% in dark, so
  /// the raised layer is always the lighter one.
  final Color scrim;

  /// See-through: [background] at alpha 0. Use it for an unselected fill, a see-through bar and the
  /// far end of a fade, so a colour animating to or from it stays in the page's tint instead of
  /// passing through black, as a bare transparent black does (principle 29, D96).
  final Color clear;

  /// The keyboard and D-pad focus ring, 2dp wide, outside a [focusGap] band: an alias of [ink].
  ///
  /// It means focus only, never selection: a selected control keeps its look and gains the ring
  /// (principle 24, D99). It is ≥ 3:1 on every layer a control sits on.
  final Color focus;

  /// The 2dp band between a control and its [focus] ring: an alias of [background]. The two tones
  /// are ≥ 9:1 apart, so one of them always stands 3:1 off whatever it touches (WCAG C40, D99).
  final Color focusGap;

  @override
  HisaabColors copyWith({
    Color? background,
    Color? surface,
    Color? sunk,
    Color? hairline,
    Color? control,
    Color? ink,
    Color? ink2,
    Color? signal,
    Color? onSignal,
    Color? display,
    Color? displayInk,
    Color? displayInk2,
    Color? blockIdle,
    Color? displayEdge,
    Color? displayEtch,
    Color? displayShadow,
    Color? displaySheen,
    Color? inverse,
    Color? danger,
    Color? scrim,
    Color? clear,
    Color? focus,
    Color? focusGap,
  }) =>
      HisaabColors(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        sunk: sunk ?? this.sunk,
        hairline: hairline ?? this.hairline,
        control: control ?? this.control,
        ink: ink ?? this.ink,
        ink2: ink2 ?? this.ink2,
        signal: signal ?? this.signal,
        onSignal: onSignal ?? this.onSignal,
        display: display ?? this.display,
        displayInk: displayInk ?? this.displayInk,
        displayInk2: displayInk2 ?? this.displayInk2,
        blockIdle: blockIdle ?? this.blockIdle,
        displayEdge: displayEdge ?? this.displayEdge,
        displayEtch: displayEtch ?? this.displayEtch,
        displayShadow: displayShadow ?? this.displayShadow,
        displaySheen: displaySheen ?? this.displaySheen,
        inverse: inverse ?? this.inverse,
        danger: danger ?? this.danger,
        scrim: scrim ?? this.scrim,
        clear: clear ?? this.clear,
        focus: focus ?? this.focus,
        focusGap: focusGap ?? this.focusGap,
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
      control: mix(control, other.control),
      ink: mix(ink, other.ink),
      ink2: mix(ink2, other.ink2),
      signal: mix(signal, other.signal),
      onSignal: mix(onSignal, other.onSignal),
      display: mix(display, other.display),
      displayInk: mix(displayInk, other.displayInk),
      displayInk2: mix(displayInk2, other.displayInk2),
      blockIdle: mix(blockIdle, other.blockIdle),
      displayEdge: mix(displayEdge, other.displayEdge),
      displayEtch: mix(displayEtch, other.displayEtch),
      displayShadow: mix(displayShadow, other.displayShadow),
      displaySheen: mix(displaySheen, other.displaySheen),
      inverse: mix(inverse, other.inverse),
      danger: mix(danger, other.danger),
      scrim: mix(scrim, other.scrim),
      clear: mix(clear, other.clear),
      focus: mix(focus, other.focus),
      focusGap: mix(focusGap, other.focusGap),
    );
  }
}
