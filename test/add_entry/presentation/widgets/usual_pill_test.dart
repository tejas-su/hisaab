import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/add_entry/presentation/widgets/usual_pill.dart';
import 'package:hisaab/core/design/app_icon.dart';
import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/core/design/hisaab_motion.dart';
import 'package:hisaab/core/extensions/build_context_extensions.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/widgets/pressable.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fixtures/habits/chai_habit.dart';
import '../../../helpers/focus_helpers.dart';
import '../../../helpers/pump_app.dart';

const ValueKey<String> _pillKey = ValueKey<String>('usual-pill');
final UsualSpend _chaiTwenty = UsualSpend(category: chai, amount: Money.fromMajor(20));
final Money _cap = Money.fromMajor(999999999);

Future<void> _pump(
  WidgetTester tester, {
  UsualSpend? usual,
  VoidCallback? onPressed,
  bool filled = false,
  bool failed = false,
  Size size = TestWindows.phone,
  double textScale = 1,
  ThemeMode themeMode = ThemeMode.light,
  bool reduceMotion = false,
}) =>
    pumpApp(
      tester,
      Builder(
        builder: (BuildContext context) => Material(
          color: context.colors.surface,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: UsualPill(
                key: _pillKey,
                usual: usual ?? _chaiTwenty,
                onPressed: onPressed ?? () {},
                filled: filled,
                failed: failed,
              ),
            ),
          ),
        ),
      ),
      size: size,
      textScale: textScale,
      themeMode: themeMode,
      reduceMotion: reduceMotion,
    );

Finder _body() => find.descendant(of: find.byKey(_pillKey), matching: find.byType(AnimatedContainer));

ShapeDecoration _decoration(WidgetTester tester) => tester.widget<AnimatedContainer>(_body()).decoration! as ShapeDecoration;

Finder _line(String text) => find.descendant(of: find.byKey(_pillKey), matching: find.text(text, findRichText: true));

Color? _lineColor(WidgetTester tester) => tester.widget<RichText>(find.descendant(of: _body(), matching: find.byType(RichText))).text.style?.color;

void main() {
  group('UsualPill (FR-AD-10)', () {
    testWidgets('shows the icon, name, amount and tag: Chai ₹20 · your usual (AC-2)', (WidgetTester tester) async {
      await _pump(tester);
      expect(_line('Chai ₹20 · your usual'), findsOneWidget);
      expect(find.descendant(of: _body(), matching: find.byType(AppIcon)), findsOneWidget);
      expect(tester.getSize(find.descendant(of: _body(), matching: find.byType(AppIcon))), const Size(20, 20));
    });

    testWidgets('is 40dp tall with a 48dp tap area (AC-2, NFR-4)', (WidgetTester tester) async {
      await _pump(tester);
      expect(tester.getSize(_body()).height, 40);
      expect(tester.getSize(find.descendant(of: find.byKey(_pillKey), matching: find.byType(Pressable))).height, 48);
      expect(tester.getSize(find.byKey(_pillKey)).height, 48);
    });

    for (final (ThemeMode mode, HisaabColors colors) in <(ThemeMode, HisaabColors)>[
      (ThemeMode.light, HisaabColors.light),
      (ThemeMode.dark, HisaabColors.dark),
    ]) {
      testWidgets('has a fully round 1dp ink2 edge on surface in ${mode.name} (AC-2)', (WidgetTester tester) async {
        await _pump(tester, themeMode: mode);
        final ShapeDecoration decoration = _decoration(tester);
        expect(decoration.color, colors.surface);
        expect(decoration.shape, StadiumBorder(side: BorderSide(color: colors.ink2)));
        expect(_lineColor(tester), colors.ink);
      });

      testWidgets('never uses the signal colour in ${mode.name}, at rest or filled (AC-2)', (WidgetTester tester) async {
        await _pump(tester, themeMode: mode);
        expect(_decoration(tester).color, isNot(colors.signal));
        await _pump(tester, themeMode: mode, filled: true);
        expect(_decoration(tester).color, isNot(colors.signal));
        expect((_decoration(tester).shape as StadiumBorder).side.color, isNot(colors.signal));
      });

      testWidgets('filled paints ink with surface text in ${mode.name} (AC-4)', (WidgetTester tester) async {
        await _pump(tester, themeMode: mode, filled: true);
        expect(_decoration(tester).color, colors.ink);
        expect(_lineColor(tester), colors.surface);
      });

      testWidgets('meets tap-target, label and contrast guidelines in ${mode.name}', (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await _pump(tester, themeMode: mode);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }

    testWidgets('reads one button: Add Chai, 20 rupees, your usual (AC-5)', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(tester);
      expect(
        tester.getSemantics(find.descendant(of: find.byKey(_pillKey), matching: find.byType(Pressable))),
        isSemantics(label: 'Add Chai, 20 rupees, your usual', isButton: true, isEnabled: true, hasTapAction: true),
      );
      expect(find.bySemanticsLabel(RegExp('Chai')), findsOneWidget);
      handle.dispose();
    });

    testWidgets("a renamed category shows its new name (BR-11)", (WidgetTester tester) async {
      await _pump(tester, usual: UsualSpend(category: chai.copyWith(customName: 'Cutting'), amount: Money.fromMajor(20)));
      expect(_line('Cutting ₹20 · your usual'), findsOneWidget);
    });

    testWidgets('a built-in category shows its localised name (BR-11)', (WidgetTester tester) async {
      await _pump(tester, usual: UsualSpend(category: food, amount: Money.fromMajor(120)));
      expect(_line('Food ₹120 · your usual'), findsOneWidget);
    });

    testWidgets('the amount is the one logged, with Indian grouping (BR-17)', (WidgetTester tester) async {
      await _pump(tester, usual: UsualSpend(category: chai, amount: Money.fromMajor(125000)));
      expect(_line('Chai ₹1,25,000 · your usual'), findsOneWidget);
    });

    testWidgets('at 1.5× text on a 320dp phone the tag drops (AC-2)', (WidgetTester tester) async {
      await _pump(tester, size: TestWindows.smallPhone, textScale: 1.5, usual: UsualSpend(category: chai, amount: Money.fromMajor(1250)));
      expect(_line('Chai ₹1,250'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('at 1× the cap amount drops the tag before it disappears (AC-2, BR-10)', (WidgetTester tester) async {
      await _pump(tester, size: TestWindows.smallPhone, usual: UsualSpend(category: chai, amount: _cap));
      expect(_line('Chai ₹99,99,99,999'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('at 2× with a 16-letter name and ₹99,99,99,999 nothing is shown (AC-2)', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pump(
        tester,
        size: TestWindows.smallPhone,
        textScale: 2,
        usual: UsualSpend(category: chai.copyWith(customName: 'Wwwwwwwwwwwwwwww'), amount: _cap),
      );
      expect(find.descendant(of: find.byKey(_pillKey), matching: find.byType(Pressable)), findsNothing);
      expect(find.descendant(of: find.byKey(_pillKey), matching: find.byType(RichText)), findsNothing);
      expect(tester.getSize(find.byKey(_pillKey)), Size.zero);
      expect(find.bySemanticsLabel(RegExp('your usual')), findsNothing);
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('it grows with the text: 40dp at 1×, taller at 1.5×, the full 48dp at 2× (AC-2)', (WidgetTester tester) async {
      await _pump(tester, textScale: 1.5);
      final double atOneAndAHalf = tester.getSize(_body()).height;
      expect(atOneAndAHalf, inInclusiveRange(40.1, 48));
      await _pump(tester, textScale: 2);
      expect(tester.getSize(_body()).height, 48);
    });

    testWidgets('text too tall for the 48dp slot is not shown (AC-2, FR-AD-1)', (WidgetTester tester) async {
      await _pump(tester, size: TestWindows.tablet, textScale: 3);
      expect(tester.getSize(find.byKey(_pillKey)), Size.zero);
    });

    for (final double scale in <double>[1, 1.5, 2]) {
      testWidgets('is never taller than 48dp at $scale× text (AC-2, FR-AD-1)', (WidgetTester tester) async {
        await _pump(tester, textScale: scale);
        expect(tester.getSize(find.byKey(_pillKey)).height, 48);
        expect(tester.getSize(_body()).height, lessThanOrEqualTo(48));
      });

      for (final (String name, Size size) in <(String, Size)>[
        ('smallPhone', TestWindows.smallPhone),
        ('phone', TestWindows.phone),
        ('phoneLandscape', TestWindows.phoneLandscape),
        ('foldableUnfolded', TestWindows.foldableUnfolded),
        ('tablet', TestWindows.tablet),
      ]) {
        testWidgets('never overflows on $name at $scale× text (NFR-4, NFR-8)', (WidgetTester tester) async {
          await _pump(tester, size: size, textScale: scale, usual: UsualSpend(category: chai, amount: _cap));
          expect(tester.takeException(), isNull);
          expect(tester.getSize(find.byKey(_pillKey)).height, lessThanOrEqualTo(48));
          expect(tester.getSize(find.byKey(_pillKey)).width, lessThanOrEqualTo(size.width - 40));
          await _pump(tester, size: size, textScale: scale, failed: true);
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('the fill animates over the 120ms press token (AC-4)', (WidgetTester tester) async {
      await _pump(tester);
      expect(tester.widget<AnimatedContainer>(_body()).duration, HisaabMotion.press);
    });

    testWidgets('under reduced motion the fill has no animation (AC-4, NFR-4)', (WidgetTester tester) async {
      await _pump(tester, reduceMotion: true);
      expect(tester.widget<AnimatedContainer>(_body()).duration, Duration.zero);
    });

    testWidgets("failed reads Couldn't save. Try again. and still takes a tap (AC-4)", (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int taps = 0;
      await _pump(tester, failed: true, onPressed: () => taps++);
      expect(_line("Couldn't save. Try again."), findsOneWidget);
      expect(_line('Chai ₹20 · your usual'), findsNothing);
      expect(tester.getSemantics(find.descendant(of: find.byKey(_pillKey), matching: find.byType(Pressable))).label, "Couldn't save. Try again.");
      await tester.tap(find.byKey(_pillKey));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('a tap calls onPressed once, anywhere in the 48dp target', (WidgetTester tester) async {
      int taps = 0;
      await _pump(tester, onPressed: () => taps++);
      await tester.tap(find.byKey(_pillKey));
      expect(taps, 1);
      await tester.tapAt(tester.getRect(find.byKey(_pillKey)).topCenter + const Offset(0, 1));
      expect(taps, 2);
    });

    testWidgets('Enter activates it and focus draws the ring (UI_DESIGN §9)', (WidgetTester tester) async {
      useFocusHighlight(FocusHighlightStrategy.alwaysTraditional);
      int taps = 0;
      await _pump(tester, onPressed: () => taps++);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(showsFocusRing(tester, find.byKey(_pillKey)), isTrue);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(taps, 1);
    });
  });
}
