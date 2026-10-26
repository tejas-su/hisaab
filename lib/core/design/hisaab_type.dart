import 'package:flutter/material.dart';

/// Builds the app [TextTheme] (UI_DESIGN §3.4): Anek Latin for amounts and titles, Mukta for text.
///
/// Every amount style uses tabular figures so digits don't shift while numbers roll.
abstract final class HisaabType {
  static const String anek = 'AnekLatin';
  static const String mukta = 'Mukta';

  static const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

  /// Returns the text theme coloured with [ink] (primary) and [ink2] (captions).
  static TextTheme textTheme({required Color ink, required Color ink2}) => TextTheme(
        displayLarge: _anek(size: 76, lineHeight: 76, width: 85, color: ink, tracking: -0.76, tabular: true),
        displayMedium: _anek(size: 60, lineHeight: 60, width: 85, color: ink, tracking: -0.6, tabular: true),
        displaySmall: _anek(size: 32, lineHeight: 34, width: 85, color: ink, tabular: true),
        headlineSmall: _anek(size: 26, lineHeight: 30, width: 100, color: ink, tracking: -0.3),
        titleLarge: _anek(size: 22, lineHeight: 28, width: 100, color: ink),
        titleMedium: _mukta(size: 16, lineHeight: 20, weight: FontWeight.w600, color: ink),
        bodyLarge: _mukta(size: 16, lineHeight: 24, weight: FontWeight.w400, color: ink),
        bodyMedium: _mukta(size: 15, lineHeight: 20, weight: FontWeight.w400, color: ink),
        bodySmall: _mukta(size: 13, lineHeight: 18, weight: FontWeight.w500, color: ink2),
        labelLarge: _mukta(size: 14, lineHeight: 20, weight: FontWeight.w600, color: ink),
        labelMedium: _mukta(size: 13, lineHeight: 16, weight: FontWeight.w600, color: ink),
        labelSmall: _mukta(size: 12, lineHeight: 14, weight: FontWeight.w600, color: ink2),
      );

  /// Row amounts in lists: Mukta bold with tabular figures.
  static TextStyle rowAmount(Color ink) =>
      _mukta(size: 17, lineHeight: 22, weight: FontWeight.w700, color: ink).copyWith(fontFeatures: _tabular);

  static TextStyle _anek({
    required double size,
    required double lineHeight,
    required double width,
    required Color color,
    double tracking = 0,
    bool tabular = false,
  }) =>
      TextStyle(
        fontFamily: anek,
        fontSize: size,
        height: lineHeight / size,
        fontWeight: FontWeight.w600,
        // why: Anek is a variable font; axes must be set explicitly for weight and width to apply.
        fontVariations: <FontVariation>[const FontVariation('wght', 600), FontVariation('wdth', width)],
        letterSpacing: tracking,
        color: color,
        fontFeatures: tabular ? _tabular : null,
      );

  static TextStyle _mukta({
    required double size,
    required double lineHeight,
    required FontWeight weight,
    required Color color,
  }) =>
      TextStyle(fontFamily: mukta, fontSize: size, height: lineHeight / size, fontWeight: weight, color: color);
}
