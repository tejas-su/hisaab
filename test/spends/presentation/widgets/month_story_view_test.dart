import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/month_story.dart';
import 'package:hisaab/spends/presentation/widgets/day_bars.dart';
import 'package:hisaab/spends/presentation/widgets/month_story_view.dart';
import 'package:hisaab/spends/presentation/widgets/story_split_bar.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/september_story.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late int asked;
  late int done;

  setUp(() {
    asked = 0;
    done = 0;
  });

  Future<void> pump(WidgetTester tester, MonthStory story, {Size size = TestWindows.phone, double textScale = 1, bool reduceMotion = false}) =>
      pumpApp(
        tester,
        Scaffold(
          body: MonthStoryView(
            story: story,
            cycleLabel: 'September',
            previousLabel: 'August',
            onAskAi: () => asked++,
            onDone: () => done++,
          ),
        ),
        size: size,
        textScale: textScale,
        reduceMotion: reduceMotion,
      );

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey<String>('story-next')));
    await tester.pumpAndSettle();
  }

  group('MonthStoryView (FR-SP-7)', () {
    testWidgets('page 1 names the month, its days and entries', (WidgetTester tester) async {
      await pump(tester, SeptemberStory.story());
      expect(find.text('September · 1 of 6'), findsOneWidget);
      expect(find.text('4 Sept – 3 Oct · 30 days'), findsOneWidget);
      expect(find.text('31 entries'), findsOneWidget);
    });

    testWidgets('tapping on through the worked example reads every page (BR-20)', (WidgetTester tester) async {
      await pump(tester, SeptemberStory.story());
      await next(tester);
      expect(find.text('₹39,600'), findsOneWidget);
      expect(find.text('of ₹45,000 that came in'), findsOneWidget);
      expect(find.text('₹4,400 left over'), findsOneWidget);
      expect(find.text('and ₹1,000 saved'), findsOneWidget);
      expect(find.byType(StorySplitBar), findsOneWidget);
      await next(tester);
      expect(find.text('The most went on Food'), findsOneWidget);
      expect(find.text('30%'), findsOneWidget);
      await next(tester);
      expect(find.text('Biggest day: Sat 12 Sept'), findsOneWidget);
      expect(find.text('₹4,850 · Train tickets'), findsOneWidget);
      expect(find.text('9 days with nothing spent.'), findsOneWidget);
      expect(find.text('Your 5 Saturdays came to ₹15,840.'), findsOneWidget);
      await next(tester);
      expect(find.text('₹7,500 less than August'), findsOneWidget);
      expect(find.text('August spent ₹47,100'), findsOneWidget);
      expect(find.text('₹3,900 less'), findsOneWidget);
      await next(tester);
      expect(find.text('That was September'), findsOneWidget);
      expect(find.text('September · 6 of 6'), findsOneWidget);
    });

    testWidgets('the last page asks the AI or is done; there is no further page', (WidgetTester tester) async {
      await pump(tester, SeptemberStory.story());
      for (int i = 0; i < 5; i++) {
        await next(tester);
      }
      await next(tester);
      expect(find.text('September · 6 of 6'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('story-ask-ai')));
      await tester.tap(find.byKey(const ValueKey<String>('story-done')));
      expect((asked, done), (1, 1));
    });

    testWidgets('the left zone goes back, and does nothing on page 1', (WidgetTester tester) async {
      await pump(tester, SeptemberStory.story());
      await tester.tap(find.byKey(const ValueKey<String>('story-back')));
      await tester.pumpAndSettle();
      expect(find.text('September · 1 of 6'), findsOneWidget);
      await next(tester);
      await tester.tap(find.byKey(const ValueKey<String>('story-back')));
      await tester.pumpAndSettle();
      expect(find.text('September · 1 of 6'), findsOneWidget);
    });

    testWidgets('a swipe and the arrow keys move pages; a slow drag does not', (WidgetTester tester) async {
      await pump(tester, SeptemberStory.story());
      await tester.fling(find.byType(MonthStoryView), const Offset(-300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('September · 2 of 6'), findsOneWidget);
      await tester.fling(find.byType(MonthStoryView), const Offset(300, 0), 1000);
      await tester.pumpAndSettle();
      expect(find.text('September · 1 of 6'), findsOneWidget);
      await tester.timedDrag(find.byType(MonthStoryView), const Offset(-40, 0), const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('September · 1 of 6'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
      expect(find.text('September · 2 of 6'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
      expect(find.text('September · 1 of 6'), findsOneWidget);
    });

    testWidgets('page 1 has no preview when the story has no page 4 (E120)', (WidgetTester tester) async {
      await pump(tester, SeptemberStory.story(entries: SeptemberStory.septemberEntries().take(8).toList()));
      expect(find.text('September · 1 of 5'), findsOneWidget);
      expect(find.byType(DayBars), findsNothing);
    });

    testWidgets('without a tracked August there are five pages (E117)', (WidgetTester tester) async {
      await pump(tester, SeptemberStory.story(previousTracked: false));
      expect(find.text('September · 1 of 5'), findsOneWidget);
    });

    testWidgets('TalkBack reads each page as one sentence, and the zones are buttons (AC-3, AC-5)', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pump(tester, SeptemberStory.story());
      await next(tester);
      expect(
        find.bySemanticsLabel(
          'You spent 39,600 rupees of 45,000 rupees that came in. 4,400 rupees left over, and 1,000 rupees saved.',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Next page'), findsOneWidget);
      expect(find.bySemanticsLabel('Previous page'), findsOneWidget);
      await next(tester);
      await next(tester);
      expect(
        find.bySemanticsLabel(
          'Biggest day: Sat 12 Sept. 4,850 rupees · Train tickets. 9 days with nothing spent. Your 5 Saturdays came to 15,840 rupees.',
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });

    testWidgets('over income reads "more than came in" on page 2 and page 6 (E119)', (WidgetTester tester) async {
      final MonthStory story = SeptemberStory.story(entries: <Entry>[
        ...SeptemberStory.septemberEntries(),
        Entry(
          id: 990,
          amount: Money.fromMajor(7500),
          kind: EntryKind.spent,
          categoryId: SeedCategoryIds.home,
          date: SeptemberStory.september.start,
          createdAt: DateTime(2026, 9, 4),
        ),
      ]);
      await pump(tester, story);
      await next(tester);
      expect(find.text('₹3,100 more than came in'), findsOneWidget);
      expect(find.text('More than came in'), findsOneWidget);
      for (int i = 0; i < 4; i++) {
        await next(tester);
      }
      expect(find.text('More than came in'), findsOneWidget);
    });

    testWidgets('no income: page 2 shows the spend alone and page 4 has no share (E118)', (WidgetTester tester) async {
      final MonthStory story =
          SeptemberStory.story(entries: SeptemberStory.septemberEntries().where((Entry e) => e.kind != EntryKind.got).toList());
      await pump(tester, story);
      await next(tester);
      expect(find.text('₹39,600'), findsOneWidget);
      expect(find.byType(StorySplitBar), findsNothing);
      await next(tester);
      await next(tester);
      expect(find.text("Bills aren't in the days."), findsOneWidget);
      for (int i = 0; i < 2; i++) {
        await next(tester);
      }
      expect(find.text('Left over'), findsNothing);
    });

    testWidgets('holds at 2.0× text on a small phone and in landscape, and under reduced motion (AC-6, AC-7)', (WidgetTester tester) async {
      for (final Size size in <Size>[TestWindows.smallPhone, TestWindows.phoneLandscape, TestWindows.splitScreenShort]) {
        await pump(tester, SeptemberStory.story(), size: size, textScale: 2, reduceMotion: true);
        for (int i = 0; i < 5; i++) {
          await next(tester);
          expect(tester.takeException(), isNull);
        }
      }
    });
  });
}
