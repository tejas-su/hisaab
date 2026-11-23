import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/spends/domain/entities/month_story.dart';
import 'package:hisaab/spends/presentation/widgets/story_motif.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('StoryMotif', () {
    test('each story page has its own motif, the month the rosette', () {
      expect(StoryPage.values.map(StoryMotif.forPage).toSet().length, StoryPage.values.length);
      expect(StoryMotif.forPage(StoryPage.month), StoryMotif.rosette);
      expect(StoryMotif.forPage(StoryPage.end), StoryMotif.blocks);
    });

    for (final StoryMotif motif in StoryMotif.values) {
      test('${motif.name} starts its drift at rest and ends it moved', () {
        expect(motif.driftAt(0, TextDirection.ltr), Matrix4.identity());
        expect(motif.driftAt(1, TextDirection.ltr), isNot(Matrix4.identity()));
      });
    }

    test('a turn mirrors in right-to-left', () {
      final Matrix4 ltr = StoryMotif.rosette.driftAt(1, TextDirection.ltr);
      final Matrix4 rtl = StoryMotif.rosette.driftAt(1, TextDirection.rtl);
      expect(rtl.entry(0, 1), closeTo(-ltr.entry(0, 1), 1e-9));
    });

    test('a slide mirrors in right-to-left', () {
      final double ltr = StoryMotif.waves.driftAt(1, TextDirection.ltr).getTranslation().x;
      expect(ltr, lessThan(0));
      expect(StoryMotif.waves.driftAt(1, TextDirection.rtl).getTranslation().x, -ltr);
    });

    test('rings grow without turning', () {
      final Matrix4 grown = StoryMotif.rings.driftAt(1, TextDirection.ltr);
      expect(grown.entry(0, 0), closeTo(1.12, 1e-9));
      expect(grown.entry(0, 1), 0);
    });
  });
}
