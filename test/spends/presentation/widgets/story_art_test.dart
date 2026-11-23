import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/core/design/hisaab_motion.dart';
import 'package:hisaab/spends/presentation/widgets/story_art.dart';
import 'package:hisaab/spends/presentation/widgets/story_art_painter.dart';
import 'package:hisaab/spends/presentation/widgets/story_grain_painter.dart';
import 'package:hisaab/spends/presentation/widgets/story_motif.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpArt(
    WidgetTester tester,
    StoryMotif motif, {
    bool reduceMotion = false,
    bool animate = true,
    Size size = TestWindows.phone,
    TextDirection direction = TextDirection.ltr,
  }) =>
      pumpApp(
        tester,
        Scaffold(
          body: Directionality(textDirection: direction, child: SizedBox.expand(child: StoryArt(motif: motif, animate: animate))),
        ),
        reduceMotion: reduceMotion,
        size: size,
        settle: false,
      );

  double opacity(WidgetTester tester) => tester.widget<FadeTransition>(find.byKey(StoryArt.fadeKey)).opacity.value;

  Matrix4 drift(WidgetTester tester) {
    final Iterable<Transform> transforms = tester.widgetList<Transform>(
      find.ancestor(of: find.byKey(StoryArt.paintKey), matching: find.byType(Transform)),
    );
    return transforms.first.transform;
  }

  group('StoryArt', () {
    for (final StoryMotif motif in StoryMotif.values) {
      for (final Size size in <Size>[TestWindows.phone, TestWindows.smallPhone, TestWindows.tablet]) {
        testWidgets('paints ${motif.name} at $size', (WidgetTester tester) async {
          await pumpArt(tester, motif, size: size);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          expect(find.byKey(StoryArt.paintKey), findsOneWidget);
        });
      }
      testWidgets('paints ${motif.name} right to left', (WidgetTester tester) async {
        await pumpArt(tester, motif, direction: TextDirection.rtl);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('settles in faded, then drifts and stops at the end of its course', (WidgetTester tester) async {
      await pumpArt(tester, StoryMotif.rosette);
      expect(opacity(tester), 0);
      await tester.pump(HisaabMotion.storyArt);
      expect(opacity(tester), 1);
      final Matrix4 midway = drift(tester);
      await tester.pump(HisaabMotion.storyDrift);
      expect(drift(tester), isNot(midway));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('with reduced motion it is still, at rest, from the first frame', (WidgetTester tester) async {
      await pumpArt(tester, StoryMotif.rays, reduceMotion: true);
      expect(opacity(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a still StoryArt never animates', (WidgetTester tester) async {
      await pumpArt(tester, StoryMotif.rosette, animate: false);
      expect(opacity(tester), 1);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('keeps its course when its theme changes', (WidgetTester tester) async {
      await pumpArt(tester, StoryMotif.waves);
      await tester.pump(HisaabMotion.storyArt);
      await pumpArt(tester, StoryMotif.waves, size: TestWindows.smallPhone);
      expect(opacity(tester), 1);
    });

    testWidgets('is decoration only: never announced, never hit', (WidgetTester tester) async {
      await pumpArt(tester, StoryMotif.blocks);
      expect(find.descendant(of: find.byType(StoryArt), matching: find.byType(IgnorePointer)), findsWidgets);
      expect(find.descendant(of: find.byType(StoryArt), matching: find.byType(ExcludeSemantics)), findsOneWidget);
    });
  });

  group('StoryArtPainter', () {
    final Color line = HisaabColors.dark.hairline;

    test('repaints only when what it draws changes', () {
      final StoryArtPainter painter = StoryArtPainter(motif: StoryMotif.waves, color: line, textDirection: TextDirection.ltr);
      expect(painter.shouldRepaint(StoryArtPainter(motif: StoryMotif.waves, color: line, textDirection: TextDirection.ltr)), isFalse);
      expect(painter.shouldRepaint(StoryArtPainter(motif: StoryMotif.rings, color: line, textDirection: TextDirection.ltr)), isTrue);
      expect(painter.shouldRepaint(StoryArtPainter(motif: StoryMotif.waves, color: line, textDirection: TextDirection.rtl)), isTrue);
      expect(painter.shouldRepaint(StoryArtPainter(motif: StoryMotif.waves, color: HisaabColors.dark.ink2, textDirection: TextDirection.ltr)), isTrue);
    });

    test('anchors on the end side, mirrored in right-to-left', () {
      const Size size = Size(400, 800);
      expect(StoryArtPainter.endX(size, 0.2, TextDirection.ltr), 320);
      expect(StoryArtPainter.endX(size, 0.2, TextDirection.rtl), 80);
      expect(StoryArtPainter.startX(size, 0.2, TextDirection.ltr), closeTo(80, 1e-9));
    });
  });

  group('StoryGrainPainter', () {
    test('is sparse: one dot per 90 square dp', () {
      expect(StoryGrainPainter.dotCount(const Size(90, 10)), 10);
      expect(StoryGrainPainter.dotCount(Size.zero), 0);
    });

    test('repaints only for a new colour', () {
      final StoryGrainPainter grain = StoryGrainPainter(color: HisaabColors.dark.hairline);
      expect(grain.shouldRepaint(StoryGrainPainter(color: HisaabColors.dark.hairline)), isFalse);
      expect(grain.shouldRepaint(StoryGrainPainter(color: HisaabColors.dark.ink2)), isTrue);
    });
  });
}
