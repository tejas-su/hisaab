
import 'package:expense_tracker/core/design/app_icon.dart';
import 'package:expense_tracker/core/design/app_icons.dart';
import 'package:expense_tracker/core/design/haptics.dart';
import 'package:expense_tracker/core/design/hisaab_colors.dart';
import 'package:expense_tracker/core/design/hisaab_glyphs.dart';
import 'package:expense_tracker/core/design/hisaab_motion.dart';
import 'package:expense_tracker/core/design/hisaab_theme.dart';
import 'package:expense_tracker/core/design/hisaab_type.dart';
import 'package:expense_tracker/ledger/domain/category_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';

void main() {
  group('HisaabMotion', () {
    test('converts Apple response/damping to stiffness (UI_DESIGN §6)', () {
      expect(HisaabMotion.snap.stiffness, closeTo(632, 1));
      expect(HisaabMotion.standard.stiffness, closeTo(322, 1));
      expect(HisaabMotion.flick.stiffness, closeTo(247, 1));
      expect(HisaabMotion.calm.stiffness, closeTo(130.5, 1));
    });

    testWidgets('reduceMotion follows the system setting', (WidgetTester tester) async {
      late bool reduced;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Builder(builder: (BuildContext context) {
            reduced = HisaabMotion.reduceMotion(context);
            return const SizedBox();
          }),
        ),
      );
      expect(reduced, isTrue);
    });
  });

  group('HisaabType', () {
    final TextTheme theme = HisaabType.textTheme(ink: const Color(0xFF000000), ink2: const Color(0xFF555555));

    test('hero and entry amounts use tabular Anek at width 85', () {
      final TextStyle? hero = theme.displayLarge;
      expect(hero?.fontFamily, HisaabType.anek);
      expect(hero?.fontSize, 76);
      expect(hero?.fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(hero?.fontVariations, contains(const FontVariation('wdth', 85)));
      expect(theme.displayMedium?.fontSize, 60);
    });

    test('body text is Mukta 16/24 and captions use ink2', () {
      expect(theme.bodyLarge?.fontFamily, HisaabType.mukta);
      expect(theme.bodyLarge?.height, 24 / 16);
      expect(theme.bodySmall?.color, const Color(0xFF555555));
    });

    test('row amounts are tabular', () {
      expect(HisaabType.rowAmount(const Color(0xFF000000)).fontFeatures, contains(const FontFeature.tabularFigures()));
    });

    test('captions are Regular and step back by ink2 colour, not weight (D68)', () {
      expect(theme.bodySmall?.fontWeight, FontWeight.w400);
      expect(theme.bodySmall?.color, const Color(0xFF555555));
    });

    test('Mukta text uses only Regular and the emphasis step; Bold is for amounts (D68)', () {
      final Iterable<TextStyle> mukta = <TextStyle?>[
        theme.titleMedium,
        theme.titleSmall,
        theme.bodyLarge,
        theme.bodyMedium,
        theme.bodySmall,
        theme.labelLarge,
        theme.labelMedium,
        theme.labelSmall,
      ].whereType<TextStyle>();
      expect(mukta.map((TextStyle s) => s.fontWeight).toSet(), <FontWeight>{FontWeight.w400, HisaabType.emphasis});
      expect(HisaabType.rowAmount(const Color(0xFF000000)).fontWeight, FontWeight.w700);
    });

    test('titleSmall is a defined small heading: Mukta 14/20 Semibold (case study 02)', () {
      expect(theme.titleSmall?.fontFamily, HisaabType.mukta);
      expect(theme.titleSmall?.fontSize, 14);
      expect(theme.titleSmall?.height, 20 / 14);
      expect(theme.titleSmall?.fontWeight, HisaabType.emphasis);
    });

    test('emphasized and regular change only the weight, to the two named steps', () {
      final TextStyle body = theme.bodyLarge!;
      expect(HisaabType.emphasized(body), body.copyWith(fontWeight: FontWeight.w600));
      expect(HisaabType.regular(theme.bodySmall!), theme.bodySmall!.copyWith(fontWeight: FontWeight.w400));
      expect(HisaabType.emphasized(null), isNull);
      expect(HisaabType.regular(null), isNull);
    });
  });

  group('HisaabTheme', () {
    test('text fields are a control fill with no edge at rest and an ink edge while typing (D88, D100)', () {
      final InputDecorationThemeData fields = HisaabTheme.light().inputDecorationTheme;
      expect(fields.filled, isTrue);
      expect(fields.fillColor, HisaabColors.light.control);
      expect(fields.enabledBorder?.borderSide, BorderSide.none);
      expect(fields.focusedBorder?.borderSide, BorderSide(color: HisaabColors.light.ink, width: 1.5));
      expect(fields.floatingLabelBehavior, FloatingLabelBehavior.never);
      expect(HisaabTheme.dark().inputDecorationTheme.fillColor, HisaabColors.dark.control);
    });

    test('installs the colour tokens and never uses red for errors', () {
      final ThemeData light = HisaabTheme.light();
      expect(light.extension<HisaabColors>(), HisaabColors.light);
      expect(light.colorScheme.error, HisaabColors.light.ink);
      expect(HisaabTheme.dark().extension<HisaabColors>(), HisaabColors.dark);
      expect(HisaabTheme.dark().brightness, Brightness.dark);
    });

    test('snackbar action is ink on the light card and marigold on the dark one', () {
      expect(HisaabTheme.light().snackBarTheme.actionTextColor, HisaabColors.light.displayInk);
      expect(HisaabTheme.dark().snackBarTheme.actionTextColor, HisaabColors.dark.signal);
    });

    test('uses predictive back transitions on Android', () {
      expect(
        HisaabTheme.light().pageTransitionsTheme.builders[TargetPlatform.android],
        isA<PredictiveBackPageTransitionsBuilder>(),
      );
    });
  });

  group('AppIcons', () {
    test('every seeded category key has an icon', () {
      for (final String key in <String>[
        'food', 'travel', 'shopping', 'bills', 'fun', 'health', 'home', 'other', 'salary', 'other_income',
      ]) {
        expect(AppIcons.byKey.containsKey(key), isTrue, reason: key);
      }
    });

    test('every curated icon key a category can carry has a glyph (D138)', () {
      expect(CategoryIcon.keys.where((String key) => !AppIcons.byKey.containsKey(key)), isEmpty);
    });

    test('the drawn glyphs back the keys the free set lacks (D138)', () {
      expect(AppIcons.forKey('chai'), same(HisaabGlyphs.cuttingChai));
      expect(AppIcons.forKey('auto'), same(HisaabGlyphs.autoRickshaw));
      expect(AppIcons.forKey('hookah'), same(HisaabGlyphs.hookah));
      expect(AppIcons.forKey('paan'), same(HisaabGlyphs.paan));
    });

    test('unknown keys fall back to "other"', () {
      expect(AppIcons.forKey('nope'), AppIcons.byKey['other']);
    });

    test('the keypad delete key is a ⌫, not the close ×', () {
      expect(AppIcons.backspace, isNot(same(HugeIcons.strokeRoundedCancel01)));
      expect(AppIcons.backspace, hasLength(2));
    });

    test('the drawn ⌫ keeps Hugeicons stroke-rounded attributes on its 24 grid', () {
      for (final List<dynamic> element in AppIcons.backspace) {
        final Map<String, String> attributes = element[1] as Map<String, String>;
        expect(element.first, 'path');
        expect(attributes['strokeWidth'], '1.5');
        expect(attributes['strokeLinecap'], 'round');
        expect(attributes['strokeLinejoin'], 'round');
        final Iterable<double> coordinates =
            RegExp(r'-?\d+(\.\d+)?').allMatches(attributes['d']!).map((RegExpMatch m) => double.parse(m[0]!));
        expect(coordinates, everyElement(inInclusiveRange(2, 22)));
      }
    });

    test('the drawn spend glyphs keep Hugeicons stroke-rounded attributes on its 24 grid', () {
      final Map<String, AppIconData> glyphs = <String, AppIconData>{
        'cuttingChai': HisaabGlyphs.cuttingChai,
        'autoRickshaw': HisaabGlyphs.autoRickshaw,
        'hookah': HisaabGlyphs.hookah,
        'paan': HisaabGlyphs.paan,
      };
      for (final MapEntry<String, AppIconData> glyph in glyphs.entries) {
        expect(glyph.value, isNotEmpty, reason: glyph.key);
        for (final List<dynamic> element in glyph.value) {
          final Map<String, String> attributes = element[1] as Map<String, String>;
          expect(attributes['strokeWidth'], '1.5', reason: glyph.key);
          final List<double> coordinates = switch (element.first) {
            'path' => <double>[
                for (final RegExpMatch m in RegExp(r'-?\d+(\.\d+)?').allMatches(attributes['d']!)) double.parse(m[0]!),
              ],
            'circle' => <double>[
                for (final String axis in <String>['cx', 'cy']) ...<double>[
                  double.parse(attributes[axis]!) - double.parse(attributes['r']!),
                  double.parse(attributes[axis]!) + double.parse(attributes['r']!),
                ],
              ],
            _ => fail('${glyph.key}: unexpected element ${element.first}'),
          };
          if (element.first == 'path') {
            expect(attributes['strokeLinecap'], 'round', reason: glyph.key);
            expect(attributes['strokeLinejoin'], 'round', reason: glyph.key);
          }
          expect(coordinates, everyElement(inInclusiveRange(2, 22)), reason: glyph.key);
        }
      }
    });

    testWidgets('the drawn spend glyphs render through AppIcon', (WidgetTester tester) async {
      for (final AppIconData glyph in <AppIconData>[
        HisaabGlyphs.cuttingChai, HisaabGlyphs.autoRickshaw, HisaabGlyphs.hookah, HisaabGlyphs.paan,
      ]) {
        await tester.pumpWidget(Directionality(textDirection: TextDirection.ltr, child: AppIcon(glyph)));
        expect(tester.takeException(), isNull);
        expect(find.byType(AppIcon), findsOneWidget);
      }
    });
  });

  group('AppIcon', () {
    testWidgets('is hidden from screen readers without a label', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(const Directionality(textDirection: TextDirection.ltr, child: AppIcon(AppIcons.home)));
      expect(find.bySemanticsLabel('Home'), findsNothing);
      handle.dispose();
    });

    testWidgets('announces its label when given one', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const Directionality(textDirection: TextDirection.ltr, child: AppIcon(AppIcons.settings, semanticLabel: 'Settings')),
      );
      expect(find.bySemanticsLabel('Settings'), findsOneWidget);
      handle.dispose();
    });
  });

  group('SystemHaptics', () {
    testWidgets('maps each event to its platform haptic', (WidgetTester tester) async {
      final List<Object?> calls = <Object?>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
        calls.add(call.arguments);
        return null;
      });
      const SystemHaptics haptics = SystemHaptics();
      await haptics.tick();
      await haptics.success();
      await haptics.reject();
      await haptics.threshold();
      expect(calls, <Object?>[
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.successNotification',
        'HapticFeedbackType.errorNotification',
        'HapticFeedbackType.lightImpact',
      ]);
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
    });
  });
}
