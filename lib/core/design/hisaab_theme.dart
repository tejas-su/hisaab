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
      dividerTheme: DividerThemeData(color: colors.hairline, thickness: 1, space: 1),
      inputDecorationTheme: _fields(colors),
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

  // why: a field is a hairline well with no edge, like chips (D88, D90); a 1.5dp ink2 edge shows focus.
  // The label never floats: with no edge it would sit outside the well.
  static InputDecorationThemeData _fields(HisaabColors colors) {
    final RoundedSuperellipseBorder shape = HisaabShapes.squircle(HisaabRadii.chip);
    final ShapedInputBorder rest = ShapedInputBorder(shape: shape, borderSide: BorderSide.none);
    return InputDecorationThemeData(
      filled: true,
      fillColor: colors.hairline,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      contentPadding: const EdgeInsetsDirectional.symmetric(horizontal: HisaabSpacing.l, vertical: HisaabSpacing.m),
      border: rest,
      enabledBorder: rest,
      disabledBorder: rest,
      focusedBorder: ShapedInputBorder(shape: shape, borderSide: BorderSide(color: colors.ink2, width: 1.5)),
      hintStyle: TextStyle(color: colors.ink2),
      labelStyle: TextStyle(color: colors.ink2),
    );
  }

  // why: SPEC D9 bans red, so even Material's error role maps to ink.
  static ColorScheme _scheme(Brightness brightness, HisaabColors colors) => ColorScheme(
        brightness: brightness,
        primary: colors.ink,
        onPrimary: colors.background,
        secondary: colors.signal,
        onSecondary: colors.onSignal,
        error: colors.ink,
        onError: colors.background,
        surface: colors.surface,
        onSurface: colors.ink,
        onSurfaceVariant: colors.ink2,
        surfaceContainerHighest: colors.sunk,
        outline: colors.hairline,
        outlineVariant: colors.hairline,
      );
}
