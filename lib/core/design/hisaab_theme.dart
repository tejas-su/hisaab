import 'package:flutter/material.dart';

import 'hisaab_colors.dart';
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
