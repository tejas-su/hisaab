import 'dart:io';

import 'package:expense_tracker/onboarding/presentation/widgets/onboarding_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

Widget _inBox(OnboardingPicture picture, {double width = 360, double height = 300}) =>
    Center(child: SizedBox(width: width, height: height, child: OnboardingIllustration(picture)));

String _shownAsset(WidgetTester tester) => (tester.widget<Image>(find.byType(Image)).image as AssetImage).assetName;

void main() {
  group('OnboardingIllustration (UI_DESIGN §5.1, D144)', () {
    for (final OnboardingPicture picture in OnboardingPicture.values) {
      testWidgets('${picture.name}: the light picture in the light look', (WidgetTester tester) async {
        await pumpApp(tester, _inBox(picture));

        expect(_shownAsset(tester), 'assets/illustrations/${picture.fileStem}_light.webp');
      });

      testWidgets('${picture.name}: the dark picture in the dark look', (WidgetTester tester) async {
        await pumpApp(tester, _inBox(picture), themeMode: ThemeMode.dark);

        expect(_shownAsset(tester), 'assets/illustrations/${picture.fileStem}_dark.webp');
      });

      for (final Brightness brightness in Brightness.values) {
        test('${picture.name}: the ${brightness.name} file ships with the app', () {
          expect(File(OnboardingIllustration.assetFor(picture, brightness)).existsSync(), isTrue);
        });
      }
    }

    testWidgets('draws nothing in a gap just under 120dp', (WidgetTester tester) async {
      await pumpApp(tester, _inBox(OnboardingPicture.payday, height: OnboardingIllustration.minHeight - 1));

      expect(find.byType(Image), findsNothing);
    });

    testWidgets('draws the picture in a gap of exactly 120dp', (WidgetTester tester) async {
      await pumpApp(tester, _inBox(OnboardingPicture.payday, height: OnboardingIllustration.minHeight));

      expect(find.byType(Image), findsOneWidget);
      expect(tester.getSize(find.byType(Image)).height, lessThanOrEqualTo(OnboardingIllustration.minHeight));
    });

    testWidgets('grows no wider than 320dp in a wide gap', (WidgetTester tester) async {
      await pumpApp(tester, _inBox(OnboardingPicture.bills, width: 600, height: 600));

      expect(tester.getSize(find.byType(Image)).width, lessThanOrEqualTo(320));
    });

    testWidgets('is hidden from TalkBack', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _inBox(OnboardingPicture.pickDay));

      expect(find.descendant(of: find.byType(ExcludeSemantics), matching: find.byType(Image)), findsOneWidget);
      handle.dispose();
    });
  });
}
