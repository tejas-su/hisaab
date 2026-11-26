import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/design/app_icon.dart';
import 'package:hisaab/core/design/app_icons.dart';
import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/spends/presentation/widgets/afford_card.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('AffordCard (FR-SP-9 AC-1, UI_DESIGN 5.4a)', () {
    Future<void> pump(WidgetTester tester, {VoidCallback? onPressed, Size size = TestWindows.phone, double textScale = 1}) =>
        pumpApp(
          tester,
          Scaffold(body: AffordCard(onPressed: onPressed ?? () {})),
          size: size,
          textScale: textScale,
        );

    testWidgets('reads "Can I afford it?" over "Check a big buy" and opens on tap', (WidgetTester tester) async {
      int taps = 0;
      await pump(tester, onPressed: () => taps++);
      expect(find.text('Can I afford it?'), findsOneWidget);
      expect(find.text('Check a big buy'), findsOneWidget);
      await tester.tap(find.byType(AffordCard));
      expect(taps, 1);
    });

    testWidgets('TalkBack reads it as one button', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      expect(
        tester.getSemantics(find.byType(AffordCard)),
        isSemantics(label: 'Can I afford it?, Check a big buy', isButton: true),
      );
      handle.dispose();
    });

    testWidgets('a borderless near-white card with a sunk well, never marigold (D66)', (WidgetTester tester) async {
      await pump(tester);
      final Container card = tester.widget<Container>(find.byKey(const ValueKey<String>('afford-card-surface')));
      final ShapeDecoration surface = card.decoration! as ShapeDecoration;
      expect(surface.color, HisaabColors.light.surface);
      expect((surface.shape as RoundedSuperellipseBorder).side, BorderSide.none);
      final Container well = tester.widget<Container>(find.byKey(const ValueKey<String>('afford-card-well')));
      expect((well.decoration! as ShapeDecoration).color, HisaabColors.light.sunk);
      final AppIcon icon = tester.widget<AppIcon>(find.byType(AppIcon));
      expect(icon.icon, AppIcons.questionLine);
      expect(icon.color, HisaabColors.light.ink);
    });

    testWidgets('the note is quieter: small ink2 text under the title', (WidgetTester tester) async {
      await pump(tester);
      final ThemeData theme = Theme.of(tester.element(find.byType(AffordCard)));
      final Text title = tester.widget<Text>(find.text('Can I afford it?'));
      final Text note = tester.widget<Text>(find.text('Check a big buy'));
      expect(title.style?.fontSize, theme.textTheme.bodyLarge?.fontSize);
      expect(note.style?.fontSize, theme.textTheme.bodySmall?.fontSize);
      expect(note.style?.color, HisaabColors.light.ink2);
      expect(tester.getTopLeft(find.text('Check a big buy')).dx, tester.getTopLeft(find.text('Can I afford it?')).dx);
    });

    testWidgets('pressed, the card sinks and the well lifts, so the glyph stays framed', (WidgetTester tester) async {
      await pump(tester);
      final TestGesture press = await tester.startGesture(tester.getCenter(find.byType(AffordCard)));
      await tester.pump();
      final Container card = tester.widget<Container>(find.byKey(const ValueKey<String>('afford-card-surface')));
      final Container well = tester.widget<Container>(find.byKey(const ValueKey<String>('afford-card-well')));
      expect((card.decoration! as ShapeDecoration).color, HisaabColors.light.sunk);
      expect((well.decoration! as ShapeDecoration).color, HisaabColors.light.surface);
      await press.up();
    });

    for (final (String name, Size size, double scale) in <(String, Size, double)>[
      ('a 320dp phone at 1.5× text', TestWindows.smallPhone, 1.5),
      ('a 320dp phone at 2× text', TestWindows.smallPhone, 2),
      ('a phone', TestWindows.phone, 1),
      ('a tablet', TestWindows.tablet, 1),
    ]) {
      testWidgets('nothing clips on $name', (WidgetTester tester) async {
        await pump(tester, size: size, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
