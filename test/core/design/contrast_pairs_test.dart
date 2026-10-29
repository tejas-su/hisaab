import 'package:expense_tracker/core/design/hisaab_colors.dart';
import 'package:expense_tracker/core/design/hisaab_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Why a pair must stand apart. Each theme sets its own floor per rule, so a future
/// high-contrast theme raises the floors and reuses [_pairs] as it is (principles 23 and 26).
enum _Rule {
  /// Text and icons that carry meaning (WCAG 2.2 SC 1.4.3).
  text,

  /// UI boundaries and graphics a user must see to operate or read them (WCAG 2.2 SC 1.4.11).
  nonText,

  /// A pressed fill is a visible step from its rest fill (UI_DESIGN §3.3).
  pressStep,

  /// Idle day blocks stand off the hero card (UI_DESIGN §3.2).
  idleBlock,

  /// The focus ring against its gap: two colours far enough apart that one of them stands 3:1
  /// off any colour next to it (WCAG 2.2 technique C40, D99).
  focusTwoTone,
}

/// The floors the light and dark themes meet (SPEC NFR-4: WCAG AA).
const Map<_Rule, double> _standard = <_Rule, double>{
  _Rule.text: 4.5,
  _Rule.nonText: 3,
  _Rule.pressStep: 1.15,
  _Rule.idleBlock: 1.5,
  _Rule.focusTwoTone: 9,
};

/// A theme the list runs against.
typedef _Theme = ({String name, HisaabColors colors, ColorScheme scheme, Map<_Rule, double> floors});

final List<_Theme> _themes = <_Theme>[
  (name: 'light', colors: HisaabColors.light, scheme: HisaabTheme.light().colorScheme, floors: _standard),
  (name: 'dark', colors: HisaabColors.dark, scheme: HisaabTheme.dark().colorScheme, floors: _standard),
];

/// A colour a pair can name: a token, a Material role, or a token seen through the scrim.
enum _Swatch {
  background,
  surface,
  sunk,
  hairline,
  control,
  ink,
  ink2,
  signal,
  onSignal,
  display,
  displayInk,
  displayInk2,
  blockIdle,
  displayEdge,
  inverse,
  focus,
  focusGap,
  displayUnderScrim,
  displayInkUnderScrim,
  primary,
  onPrimary,
  primaryContainer,
  onPrimaryContainer,
  secondary,
  onSecondary,
  secondaryContainer,
  onSecondaryContainer,
  tertiary,
  onTertiary,
  tertiaryContainer,
  onTertiaryContainer,
  error,
  onError,
  errorContainer,
  onErrorContainer,
  schemeSurface,
  onSurface,
  onSurfaceVariant,
  inverseSurface,
  onInverseSurface,
  outline;

  Color of(_Theme theme) {
    final HisaabColors c = theme.colors;
    final ColorScheme s = theme.scheme;
    return switch (this) {
      background => c.background,
      surface => c.surface,
      sunk => c.sunk,
      hairline => c.hairline,
      control => c.control,
      ink => c.ink,
      ink2 => c.ink2,
      signal => c.signal,
      onSignal => c.onSignal,
      display => c.display,
      displayInk => c.displayInk,
      displayInk2 => c.displayInk2,
      blockIdle => c.blockIdle,
      displayEdge => c.displayEdge,
      inverse => c.inverse,
      focus => c.focus,
      focusGap => c.focusGap,
      displayUnderScrim => Color.alphaBlend(c.scrim, c.display),
      displayInkUnderScrim => Color.alphaBlend(c.scrim, c.displayInk),
      primary => s.primary,
      onPrimary => s.onPrimary,
      primaryContainer => s.primaryContainer,
      onPrimaryContainer => s.onPrimaryContainer,
      secondary => s.secondary,
      onSecondary => s.onSecondary,
      secondaryContainer => s.secondaryContainer,
      onSecondaryContainer => s.onSecondaryContainer,
      tertiary => s.tertiary,
      onTertiary => s.onTertiary,
      tertiaryContainer => s.tertiaryContainer,
      onTertiaryContainer => s.onTertiaryContainer,
      error => s.error,
      onError => s.onError,
      errorContainer => s.errorContainer,
      onErrorContainer => s.onErrorContainer,
      schemeSurface => s.surface,
      onSurface => s.onSurface,
      onSurfaceVariant => s.onSurfaceVariant,
      inverseSurface => s.inverseSurface,
      onInverseSurface => s.onInverseSurface,
      outline => s.outline,
    };
  }
}

/// One foreground on one background, the rule it must meet, and where it shows. [only] limits a
/// pair to themes of one brightness when the other theme draws it differently.
typedef _Pair = ({_Swatch fg, _Swatch bg, _Rule rule, String where, Brightness? only});

_Pair _pair(_Swatch fg, _Swatch bg, _Rule rule, String where, {Brightness? only}) =>
    (fg: fg, bg: bg, rule: rule, where: where, only: only);

/// Every contrast pair in the app, checked in every theme (UI_DESIGN §3.2).
final List<_Pair> _pairs = <_Pair>[
  // Body text on every surface and fill. Control is the chip, Back well and field fill on the page;
  // hairline is their fill on a surface layer (D100).
  for (final _Swatch bg in <_Swatch>[_Swatch.background, _Swatch.surface, _Swatch.sunk, _Swatch.hairline, _Swatch.control]) ...<_Pair>[
    _pair(_Swatch.ink, bg, _Rule.text, 'text'),
    _pair(_Swatch.ink2, bg, _Rule.text, 'secondary text, labels and hints'),
  ],
  _pair(_Swatch.onSignal, _Swatch.signal, _Rule.text, 'the Add and Next keys'),
  _pair(_Swatch.displayInk, _Swatch.display, _Rule.text, 'the hero'),
  _pair(_Swatch.displayInk2, _Swatch.display, _Rule.text, 'the hero’s secondary text'),
  _pair(_Swatch.background, _Swatch.ink2, _Rule.text, 'page-coloured text on an ink2 fill (D89; picks are ink since D100)'),
  _pair(_Swatch.background, _Swatch.ink, _Rule.text, 'a flashed tile’s label, and a picked chip’s label, check and detail (D100)'),
  _pair(_Swatch.displayInkUnderScrim, _Swatch.displayUnderScrim, _Rule.text, 'the hero behind the tray (D93)'),
  _pair(_Swatch.signal, _Swatch.display, _Rule.nonText, 'today’s block on the dark hero', only: Brightness.dark),
  _pair(_Swatch.displayEdge, _Swatch.display, _Rule.nonText, 'today’s edge on the light hero', only: Brightness.light),
  _pair(_Swatch.displayEdge, _Swatch.signal, _Rule.nonText, 'today’s edge against marigold', only: Brightness.light),
  _pair(_Swatch.hairline, _Swatch.sunk, _Rule.pressStep, 'a pressed key or well'),
  _pair(_Swatch.sunk, _Swatch.control, _Rule.pressStep, 'a pressed chip or Back well on the page (D100)'),
  // A control stands off the layer it sits on: control on the page, hairline on a card or tray (D100).
  _pair(_Swatch.control, _Swatch.background, _Rule.pressStep, 'a resting chip, Back well or field on the page (D100)'),
  _pair(_Swatch.hairline, _Swatch.surface, _Rule.pressStep, 'a resting chip or field on a card, the tray or a sheet (D100)'),
  _pair(_Swatch.blockIdle, _Swatch.display, _Rule.idleBlock, 'idle day blocks'),
  // The focus ring sits on the layer around a control; its gap sits against the control (D99).
  for (final _Swatch layer in <_Swatch>[_Swatch.background, _Swatch.surface, _Swatch.sunk, _Swatch.display])
    _pair(_Swatch.focus, layer, _Rule.nonText, 'the focus ring around a control on this layer'),
  _pair(_Swatch.focus, _Swatch.focusGap, _Rule.focusTwoTone, 'the focus ring against its gap'),
  // why: a control's own fill touches the gap, not the ring, so one of the two tones must stand off
  // it (C40). Ink on ink2 is 2.5:1 and light ink on marigold 1.6:1, so the gap carries those.
  _pair(_Swatch.focusGap, _Swatch.ink2, _Rule.nonText, 'the focus gap against an ink2 fill'),
  _pair(_Swatch.focusGap, _Swatch.ink, _Rule.nonText, 'the focus gap against a picked chip (D100)'),
  _pair(_Swatch.focus, _Swatch.control, _Rule.nonText, 'the focus ring against a resting chip on the page (D100)'),
  _pair(_Swatch.focus, _Swatch.hairline, _Rule.nonText, 'the focus ring against a resting chip on a card (D100)'),
  _pair(_Swatch.ink, _Swatch.control, _Rule.nonText, 'a focused field’s ink edge on its control fill (D100)'),
  _pair(_Swatch.ink, _Swatch.hairline, _Rule.nonText, 'a focused field’s ink edge on a hairline fill (D100)'),
  _pair(_Swatch.focus, _Swatch.signal, _Rule.nonText, 'the focus ring beside a marigold key', only: Brightness.light),
  _pair(_Swatch.focusGap, _Swatch.signal, _Rule.nonText, 'the focus gap against a marigold key', only: Brightness.dark),
  // Material roles, which Material widgets draw on their own (D94, D95).
  _pair(_Swatch.outline, _Swatch.surface, _Rule.nonText, 'the Switch’s off thumb and edge on a card'),
  _pair(_Swatch.outline, _Swatch.sunk, _Rule.nonText, 'the Switch’s off thumb on its track'),
  _pair(_Swatch.primaryContainer, _Swatch.primary, _Rule.nonText, 'a pressed or focused Switch thumb on its track'),
  _pair(_Swatch.onPrimary, _Swatch.primary, _Rule.text, 'Material primary'),
  _pair(_Swatch.onPrimaryContainer, _Swatch.primaryContainer, _Rule.text, 'Material primary container'),
  _pair(_Swatch.onSecondary, _Swatch.secondary, _Rule.text, 'Material secondary'),
  _pair(_Swatch.onSecondaryContainer, _Swatch.secondaryContainer, _Rule.text, 'Material secondary container'),
  _pair(_Swatch.onTertiary, _Swatch.tertiary, _Rule.text, 'Material tertiary'),
  _pair(_Swatch.onTertiaryContainer, _Swatch.tertiaryContainer, _Rule.text, 'Material tertiary container'),
  _pair(_Swatch.onError, _Swatch.error, _Rule.text, 'Material error'),
  _pair(_Swatch.onErrorContainer, _Swatch.errorContainer, _Rule.text, 'Material error container'),
  _pair(_Swatch.onSurface, _Swatch.schemeSurface, _Rule.text, 'Material surface'),
  _pair(_Swatch.onSurfaceVariant, _Swatch.schemeSurface, _Rule.text, 'Material surface, secondary text'),
  _pair(_Swatch.onInverseSurface, _Swatch.inverseSurface, _Rule.text, 'a Tooltip'),
  _pair(_Swatch.background, _Swatch.inverse, _Rule.text, 'snackbar text and its Undo (D105)'),
];

double _contrast(Color a, Color b) {
  final double la = a.computeLuminance();
  final double lb = b.computeLuminance();
  final double lighter = la > lb ? la : lb;
  final double darker = la > lb ? lb : la;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  group('Contrast pairs (SPEC NFR-4, principle 26)', () {
    for (final _Theme theme in _themes) {
      final Brightness brightness = theme.scheme.brightness;
      for (final _Pair pair in _pairs.where((_Pair p) => p.only == null || p.only == brightness)) {
        final double floor = theme.floors[pair.rule]!;
        test('${theme.name}: ${pair.fg.name} on ${pair.bg.name} ≥ $floor (${pair.rule.name}: ${pair.where})', () {
          expect(_contrast(pair.fg.of(theme), pair.bg.of(theme)), greaterThanOrEqualTo(floor));
        });
      }
    }

    test('every theme sets a floor for every rule', () {
      for (final _Theme theme in _themes) {
        expect(theme.floors.keys.toSet(), _Rule.values.toSet(), reason: theme.name);
      }
    });
  });
}
