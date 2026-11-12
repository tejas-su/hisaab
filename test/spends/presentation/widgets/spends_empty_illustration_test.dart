import 'dart:io';

import 'package:hisaab/spends/presentation/widgets/spends_empty_illustration.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

Widget _inBox({double width = 360, double height = 300}) =>
    Center(child: SizedBox(width: width, height: height, child: const SpendsEmptyIllustration()));

String _shownAsset(WidgetTester tester) => (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName;

void main() {
  group('SpendsEmptyIllustration (UI_DESIGN Spends, D150)', () {
    testWidgets('the light picture in the light look', (WidgetTester tester) async {
      await pumpApp(tester, _inBox());

      expect(_shownAsset(tester), 'assets/illustrations/spends_empty_light.webp');
    });

    testWidgets('the dark picture in the dark look', (WidgetTester tester) async {
      await pumpApp(tester, _inBox(), themeMode: ThemeMode.dark);

      expect(_shownAsset(tester), 'assets/illustrations/spends_empty_dark.webp');
    });

    for (final Brightness brightness in Brightness.values) {
      test('the ${brightness.name} file ships with the app', () {
        expect(File(SpendsEmptyIllustration.assetFor(brightness)).existsSync(), isTrue);
      });
    }

    testWidgets('draws nothing in a gap just under 120dp', (WidgetTester tester) async {
      await pumpApp(tester, _inBox(height: SpendsEmptyIllustration.minHeight - 1));

      expect(find.byType(Image), findsNothing);
    });

    testWidgets('draws the picture in a gap of exactly 120dp, within it', (WidgetTester tester) async {
      await pumpApp(tester, _inBox(height: SpendsEmptyIllustration.minHeight));

      expect(find.byType(Image), findsOneWidget);
      expect(tester.getSize(find.byType(Image)).height, lessThanOrEqualTo(SpendsEmptyIllustration.minHeight));
    });

    testWidgets('grows no wider than 300dp in a wide gap', (WidgetTester tester) async {
      await pumpApp(tester, _inBox(width: 600, height: 600));

      expect(tester.getSize(find.byType(Image)).width, lessThanOrEqualTo(300));
    });

    testWidgets('is hidden from TalkBack', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _inBox());

      expect(find.descendant(of: find.byType(ExcludeSemantics), matching: find.byType(Image)), findsOneWidget);
      handle.dispose();
    });
  });
}
