import 'package:flutter/material.dart';

import 'hisaab_colors.dart';
import 'hisaab_dimensions.dart';
import 'hisaab_shapes.dart';
import 'hisaab_type.dart';

/// Builds the app's [ThemeData] from the tokens; the only place Material is configured.
abstract final class HisaabTheme {
  static ThemeData light() => _build(Brightness.light, HisaabColors.light);

  static ThemeData dark() => _build(Brightness.dark, HisaabColors.dark);

  static ThemeData _build(Brightness brightness, HisaabColors colors) {
    final TextTheme textTheme = HisaabType.textTheme(ink: colors.ink, ink2: colors.ink2);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: _scheme(brightness, colors),
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      textTheme: textTheme,
      fontFamily: HisaabType.mukta,
      iconTheme: IconThemeData(color: colors.ink),
      // why: a see-through bar in the page tint, so Material reads its brightness from the page and
      // picks status icons that contrast with it (bare transparent read as black, D96).
      appBarTheme: AppBarTheme(backgroundColor: colors.clear),
      dividerTheme: DividerThemeData(color: colors.hairline, thickness: 1, space: 1),
      inputDecorationTheme: _fields(colors),
      bottomSheetTheme: BottomSheetThemeData(modalBarrierColor: colors.scrim),
      dialogTheme: DialogThemeData(barrierColor: colors.scrim),
      splashFactory: InkRipple.splashFactory,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.display,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: colors.displayInk),
        // why: the light card is near-white, where marigold text would be 1.6:1.
        actionTextColor: brightness == Brightness.light ? colors.displayInk : colors.signal,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
      extensions: <ThemeExtension<dynamic>>[colors],
    );
  }

  // why: a field is a control well with no edge, like chips (D88, D100); a 1.5dp ink edge shows focus.
  // A field on a surface layer overrides the fill with hairline (D100). The label never floats: with
  // no edge it would sit outside the well.
  static InputDecorationThemeData _fields(HisaabColors colors) {
    final RoundedSuperellipseBorder shape = HisaabShapes.squircle(HisaabRadii.chip);
    final ShapedInputBorder rest = ShapedInputBorder(shape: shape, borderSide: BorderSide.none);
    return InputDecorationThemeData(
      filled: true,
      fillColor: colors.control,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.l, vertical: HisaabSpacing.m),
      border: rest,
      enabledBorder: rest,
      disabledBorder: rest,
      focusedBorder: ShapedInputBorder(shape: shape, borderSide: BorderSide(color: colors.ink, width: 1.5)),
      hintStyle: TextStyle(color: colors.ink2),
      labelStyle: TextStyle(color: colors.ink2),
    );
  }

  // why: SPEC D9 bans red, so even Material's error role maps to ink. `outline` is Material's
  // 3:1 boundary role (the Switch's off thumb and track edge), so it is ink2; the decorative
  // hairline is `outlineVariant`. `primaryContainer` keeps a pressed or focused Switch thumb
  // visible on its ink track (D94). Every role is set, because an unset one falls back to the
  // nearest given colour: `secondary` was marigold, so `tertiary*` and `secondaryContainer`
  // were too. Marigold reaches a widget only through `HisaabColors.signal` (D95). The `*Fixed`
  // roles and `shadow` keep Flutter's fallbacks (`*Fixed` follow the ink roles above).
  static ColorScheme _scheme(Brightness brightness, HisaabColors colors) => ColorScheme(
        brightness: brightness,
        primary: colors.ink,
        onPrimary: colors.background,
        primaryContainer: colors.sunk,
        onPrimaryContainer: colors.ink,
        secondary: colors.ink,
        onSecondary: colors.background,
        secondaryContainer: colors.sunk,
        onSecondaryContainer: colors.ink,
        tertiary: colors.ink,
        onTertiary: colors.background,
        tertiaryContainer: colors.sunk,
        onTertiaryContainer: colors.ink,
        error: colors.ink,
        onError: colors.background,
        errorContainer: colors.sunk,
        onErrorContainer: colors.ink,
        surface: colors.surface,
        onSurface: colors.ink,
        surfaceDim: colors.surface,
        surfaceBright: colors.surface,
        surfaceContainerLowest: colors.surface,
        surfaceContainerLow: colors.surface,
        surfaceContainer: colors.surface,
        surfaceContainerHigh: colors.surface,
        surfaceContainerHighest: colors.sunk,
        onSurfaceVariant: colors.ink2,
        outline: colors.ink2,
        outlineVariant: colors.hairline,
        scrim: colors.scrim,
        inverseSurface: colors.ink,
        onInverseSurface: colors.surface,
        inversePrimary: colors.background,
        surfaceTint: colors.ink,
      );
}
