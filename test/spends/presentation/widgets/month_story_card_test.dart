import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/design/hisaab_colors.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/month_story.dart';
import 'package:hisaab/spends/presentation/widgets/day_bars.dart';
import 'package:hisaab/spends/presentation/widgets/month_story_card.dart';
import 'package:hisaab/spends/presentation/widgets/month_story_row.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fixtures/ledger/september_story.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late int taps;

  setUp(() => taps = 0);

  Future<void> pumpCard(WidgetTester tester, MonthStory story, {double textScale = 1, Size size = TestWindows.phone}) => pumpApp(
        tester,
        Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[MonthStoryCard(story: story, cycleLabel: 'September', onPressed: () => taps++)],
          ),
        ),
        textScale: textScale,
        size: size,
      );

  group('MonthStoryCard (FR-SP-7 AC-1)', () {
    testWidgets('shows Your month, the headline, a preview and See the story', (WidgetTester tester) async {
      await pumpCard(tester, SeptemberStory.story());
      expect(find.text('Your month'), findsOneWidget);
      expect(find.text('₹4,400 left over'), findsOneWidget);
      expect(find.byType(DayBars), findsOneWidget);
      expect(find.text('See the story'), findsOneWidget);
    });

    testWidgets('is on the dark surface even in the light theme (AC-4)', (WidgetTester tester) async {
      await pumpCard(tester, SeptemberStory.story());
      final Container surface = tester.widget(find.byKey(const ValueKey<String>('month-story-card-surface')));
      expect((surface.decoration! as ShapeDecoration).color, HisaabColors.dark.surface);
    });

    testWidgets('one button for TalkBack, with the spoken headline; a tap opens the story', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpCard(tester, SeptemberStory.story());
      expect(find.bySemanticsLabel('Your September story. 4,400 rupees left over.'), findsOneWidget);
      await tester.tap(find.byType(MonthStoryCard));
      expect(taps, 1);
      semantics.dispose();
    });

    testWidgets('with nothing coming in, it says what was spent (E118)', (WidgetTester tester) async {
      await pumpCard(
        tester,
        SeptemberStory.story(entries: SeptemberStory.septemberEntries().where((Entry e) => e.kind != EntryKind.got).toList()),
      );
      expect(find.text('₹39,600 spent'), findsOneWidget);
    });

    testWidgets('a story without page 4 has no preview', (WidgetTester tester) async {
      await pumpCard(tester, SeptemberStory.story(entries: SeptemberStory.septemberEntries().take(8).toList()));
      expect(find.byType(DayBars), findsNothing);
    });

    testWidgets('holds at 2.0× text on a small phone', (WidgetTester tester) async {
      await pumpCard(tester, SeptemberStory.story(), textScale: 2, size: TestWindows.smallPhone);
      expect(tester.takeException(), isNull);
    });
  });

  group('MonthStoryRow (FR-SP-7 AC-2)', () {
    testWidgets('reads "September is done. See your month" as one button and opens the story', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pumpApp(tester, Scaffold(body: MonthStoryRow(previousLabel: 'September', onPressed: () => taps++)));
      expect(find.bySemanticsLabel('September is done. See your month'), findsOneWidget);
      await tester.tap(find.byType(MonthStoryRow));
      expect(taps, 1);
      expect(tester.getSize(find.byType(MonthStoryRow)).height, greaterThanOrEqualTo(48));
      semantics.dispose();
    });
  });
}
