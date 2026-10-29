import 'package:expense_tracker/core/design/hisaab_colors.dart';
import 'package:expense_tracker/core/design/hisaab_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every colour role a [ColorScheme] exposes, by name (deprecated aliases left out).
Map<String, Color> _roles(ColorScheme s) => <String, Color>{
      'primary': s.primary,
      'onPrimary': s.onPrimary,
      'primaryContainer': s.primaryContainer,
      'onPrimaryContainer': s.onPrimaryContainer,
      'primaryFixed': s.primaryFixed,
      'primaryFixedDim': s.primaryFixedDim,
      'onPrimaryFixed': s.onPrimaryFixed,
      'onPrimaryFixedVariant': s.onPrimaryFixedVariant,
      'secondary': s.secondary,
      'onSecondary': s.onSecondary,
      'secondaryContainer': s.secondaryContainer,
      'onSecondaryContainer': s.onSecondaryContainer,
      'secondaryFixed': s.secondaryFixed,
      'secondaryFixedDim': s.secondaryFixedDim,
      'onSecondaryFixed': s.onSecondaryFixed,
      'onSecondaryFixedVariant': s.onSecondaryFixedVariant,
      'tertiary': s.tertiary,
      'onTertiary': s.onTertiary,
      'tertiaryContainer': s.tertiaryContainer,
      'onTertiaryContainer': s.onTertiaryContainer,
      'tertiaryFixed': s.tertiaryFixed,
      'tertiaryFixedDim': s.tertiaryFixedDim,
      'onTertiaryFixed': s.onTertiaryFixed,
      'onTertiaryFixedVariant': s.onTertiaryFixedVariant,
      'error': s.error,
      'onError': s.onError,
      'errorContainer': s.errorContainer,
      'onErrorContainer': s.onErrorContainer,
      'surface': s.surface,
      'onSurface': s.onSurface,
      'surfaceDim': s.surfaceDim,
      'surfaceBright': s.surfaceBright,
      'surfaceContainerLowest': s.surfaceContainerLowest,
      'surfaceContainerLow': s.surfaceContainerLow,
      'surfaceContainer': s.surfaceContainer,
      'surfaceContainerHigh': s.surfaceContainerHigh,
      'surfaceContainerHighest': s.surfaceContainerHighest,
      'onSurfaceVariant': s.onSurfaceVariant,
      'outline': s.outline,
      'outlineVariant': s.outlineVariant,
      'shadow': s.shadow,
      'scrim': s.scrim,
      'inverseSurface': s.inverseSurface,
      'onInverseSurface': s.onInverseSurface,
      'inversePrimary': s.inversePrimary,
      'surfaceTint': s.surfaceTint,
    };

/// Roles allowed to be marigold, each with its reason. Empty: no Material widget may draw the
/// signal on its own; a widget that means "today / act" reads `HisaabColors.signal` (D95).
const Map<String, String> _signalRoles = <String, String>{};

void main() {
  for (final (String name, ThemeData theme, HisaabColors colors) in <(String, ThemeData, HisaabColors)>[
    ('light', HisaabTheme.light(), HisaabColors.light),
    ('dark', HisaabTheme.dark(), HisaabColors.dark),
  ]) {
    group('HisaabTheme $name: Material roles map to tokens', () {
      final ColorScheme scheme = theme.colorScheme;

      // why: the contrast of outline and primaryContainer is in contrast_pairs_test.dart (D98).
      test('outline is the 3:1 boundary role (Switch off thumb and track edge, WCAG 1.4.11)', () {
        expect(scheme.outline, colors.ink2);
      });

      test('outlineVariant is the decorative hairline', () {
        expect(scheme.outlineVariant, colors.hairline);
      });

      test('no role is the signal, except the allowlist (principle 25)', () {
        final Iterable<String> marigold =
            _roles(scheme).entries.where((MapEntry<String, Color> role) => role.value == colors.signal).map((MapEntry<String, Color> role) => role.key);
        expect(marigold.toSet(), _signalRoles.keys.toSet());
      });

      test('secondary and tertiary roles are ink on sunk, like primary', () {
        for (final (Color role, Color on, Color container, Color onContainer) in <(Color, Color, Color, Color)>[
          (scheme.secondary, scheme.onSecondary, scheme.secondaryContainer, scheme.onSecondaryContainer),
          (scheme.tertiary, scheme.onTertiary, scheme.tertiaryContainer, scheme.onTertiaryContainer),
        ]) {
          expect((role, on, container, onContainer), (colors.ink, colors.background, colors.sunk, colors.ink));
        }
      });

      test('error roles are ink, never red: state is shown in words (SPEC D9)', () {
        expect(
          (scheme.error, scheme.onError, scheme.errorContainer, scheme.onErrorContainer),
          (colors.ink, colors.background, colors.sunk, colors.ink),
        );
      });

      test('surface roles sit on the surface layer; the highest container is sunk', () {
        for (final Color role in <Color>[
          scheme.surfaceDim,
          scheme.surfaceBright,
          scheme.surfaceContainerLowest,
          scheme.surfaceContainerLow,
          scheme.surfaceContainer,
          scheme.surfaceContainerHigh,
        ]) {
          expect(role, colors.surface);
        }
        expect(scheme.surfaceContainerHighest, colors.sunk);
      });

      test('inverse roles: a Tooltip is ink with surface text', () {
        expect(
          (scheme.inverseSurface, scheme.onInverseSurface, scheme.inversePrimary, scheme.surfaceTint),
          (colors.ink, colors.surface, colors.background, colors.ink),
        );
      });

      test('app bars are see-through in the page colour, not in black (principle 29)', () {
        expect(theme.appBarTheme.backgroundColor, colors.clear);
      });

      test('sheets and dialogs dim the page with the scrim token', () {
        expect(scheme.scrim, colors.scrim);
        expect(theme.bottomSheetTheme.modalBarrierColor, colors.scrim);
        expect(theme.dialogTheme.barrierColor, colors.scrim);
      });
    });
  }
}
