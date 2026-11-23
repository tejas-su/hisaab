import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/design/hisaab_motion.dart';
import 'package:hisaab/spends/domain/entities/month_story.dart';
import 'package:hisaab/spends/presentation/widgets/story_art.dart';
import 'package:hisaab/spends/presentation/widgets/story_backdrop.dart';
import 'package:hisaab/spends/presentation/widgets/story_motif.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart';

void main() {
  Future<void> pumpBackdrop(WidgetTester tester, StoryPage page, {bool reduceMotion = false}) => pumpApp(
        tester,
        Scaffold(body: SizedBox.expand(child: StoryBackdrop(page: page))),
        reduceMotion: reduceMotion,
      );

  group('StoryBackdrop', () {
    testWidgets("shows the page's motif and crossfades to the next page's", (WidgetTester tester) async {
      await pumpBackdrop(tester, StoryPage.month);
      expect(tester.widget<StoryArt>(find.byType(StoryArt)).motif, StoryMotif.rosette);
      await pumpBackdrop(tester, StoryPage.kept);
      expect(tester.widget<StoryArt>(find.byType(StoryArt)).motif, StoryMotif.rings);
      expect(tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration, HisaabMotion.resize);
    });

    testWidgets('with reduced motion the art swaps in a short crossfade', (WidgetTester tester) async {
      await pumpBackdrop(tester, StoryPage.days, reduceMotion: true);
      expect(tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration, HisaabMotion.reducedCrossfade);
    });
  });
}
