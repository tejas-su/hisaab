import 'dart:ui';

import 'package:hisaab/core/design/hisaab_theme.dart';
import 'package:hisaab/core/design/hisaab_type.dart';
import 'package:hisaab/core/layout/app_layout_scope.dart';
import 'package:hisaab/l10n/gen/app_localizations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Window presets in logical pixels for adaptive-layout tests.
abstract final class TestWindows {
  static const Size phone = Size(412, 915);
  static const Size phoneLandscape = Size(915, 412);
  static const Size smallPhone = Size(320, 568);
  static const Size foldableUnfolded = Size(673, 841);
  static const Size foldableLandscape = Size(841, 701);
  static const Size tablet = Size(1280, 800);
}

bool _fontsLoaded = false;

/// Loads the bundled Anek Latin and Mukta fonts so layout tests measure real glyph widths
/// instead of the test font's 1em squares.
Future<void> loadAppFonts() async {
  if (_fontsLoaded) {
    return;
  }
  final FontLoader anek = FontLoader(HisaabType.anek)..addFont(rootBundle.load('assets/fonts/AnekLatin-Variable.ttf'));
  final FontLoader mukta = FontLoader(HisaabType.mukta);
  for (final String weight in <String>['Regular', 'Medium', 'SemiBold', 'Bold']) {
    mukta.addFont(rootBundle.load('assets/fonts/Mukta-$weight.ttf'));
  }
  await Future.wait(<Future<void>>[anek.load(), mukta.load()]);
  _fontsLoaded = true;
}

/// Pumps [child] inside the app's theme, localisations and [AppLayoutScope], in a window of
/// [size] with optional [displayFeatures] (folds, hinges), [textScale] and [reduceMotion].
/// Pass `settle: false` to inspect an entrance animation from its first frame.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  Size size = TestWindows.phone,
  List<DisplayFeature> displayFeatures = const <DisplayFeature>[],
  ThemeMode themeMode = ThemeMode.light,
  double textScale = 1,
  bool reduceMotion = false,
  bool settle = true,
}) async {
  await tester.runAsync(loadAppFonts);
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1
    ..displayFeatures = displayFeatures;
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  if (reduceMotion) {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: HisaabTheme.light(),
      darkTheme: HisaabTheme.dark(),
      themeMode: themeMode,
      locale: const Locale('en', 'IN'),
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (BuildContext context, Widget? app) => AppLayoutScope(child: app ?? const SizedBox()),
      home: child,
    ),
  );
  if (settle) {
    await tester.pumpAndSettle();
  }
}
