import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/presentation/widgets/insights_card.dart';
import 'package:hisaab/spends/presentation/widgets/pace_card.dart';
import 'package:hisaab/spends/presentation/widgets/spends_card.dart';
import 'package:hisaab/spends/presentation/widgets/spends_empty_illustration.dart';
import 'package:hisaab/spends/presentation/widgets/where_it_went_card.dart';
import 'package:hisaab/spends/spends.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

const PayCycle _october = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3));

void main() {
  late FakeServices services;
  late SpendsBloc bloc;
  late List<(PayCycle, Option<int>)> opened;
  late List<PayCycle> asked;

  setUp(() {
    services = FakeServices();
    bloc = services.spendsBloc();
    opened = <(PayCycle, Option<int>)>[];
    asked = <PayCycle>[];
  });

  tearDown(() async {
    await bloc.close();
    await services.dispose();
  });

  Future<void> pump(WidgetTester tester, {bool load = true, Size size = TestWindows.phone, double textScale = 1, ThemeMode theme = ThemeMode.light}) async {
    if (load) {
      await tester.runAsync(() => bloc.dispatch(const SpendsLoadRequested()));
    }
    await pumpApp(
      tester,
      BlocProvider<SpendsBloc>.value(
        value: bloc,
        child: Scaffold(
          body: SpendsPage(
            today: WorkedExample.today,
            onSeeEntries: (PayCycle cycle, Option<int> category) => opened.add((cycle, category)),
            onAskAi: asked.add,
          ),
        ),
      ),
      size: size,
      textScale: textScale,
      themeMode: theme,
    );
  }

  // why: Spends is a lazy list, so the insights card under the taller pace card (D135) is built
  // only once it scrolls near the screen.
  Future<void> scrollToInsights(WidgetTester tester) =>
      tester.scrollUntilVisible(find.byType(InsightsCard), 100, scrollable: find.byType(Scrollable).first);

  // A tracked September makes Food "up" and brings the limit offer.
  void trackSeptember() {
    for (final (int id, int rupees, int category, EntryKind kind, CalendarDate date) in <(int, int, int, EntryKind, CalendarDate)>[
      (201, 45000, SeedCategoryIds.salary, EntryKind.got, const CalendarDate(2026, 9, 4)),
      (202, 2000, SeedCategoryIds.food, EntryKind.spent, const CalendarDate(2026, 9, 10)),
    ]) {
      services.ledger.entries.add(
        Entry(id: id, amount: Money.fromMajor(rupees), kind: kind, categoryId: category, date: date, createdAt: DateTime(2026, 9, 4)),
      );
    }
  }

  group('SpendsPage (FR-SP)', () {
    testWidgets('loading shows the title only', (WidgetTester tester) async {
      await pump(tester, load: false);
      expect(find.text('Spends'), findsOneWidget);
      expect(find.byType(PaceCard), findsNothing);
    });

    testWidgets('worked example: October, ₹27,570 of ₹45,000, fixed axis, below pace, rows', (WidgetTester tester) async {
      await pump(tester);
      expect(find.text('October'), findsOneWidget);
      expect(find.textContaining('₹27,570'), findsOneWidget);
      expect(find.textContaining('of ₹45,000'), findsOneWidget);
      expect(find.text('Spending slower'), findsOneWidget);
      expect(find.text('Where it went'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('69%'), findsOneWidget);
      expect(find.text('₹19,010'), findsOneWidget);
      expect(find.byType(InsightsCard), findsNothing);
    });

    testWidgets('TalkBack reads the pace card as one sentence', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      // The gap and the forecast follow the verdict on the current cycle (D133).
      expect(
        find.bySemanticsLabel(
          '27,570 rupees spent so far of 45,000 rupees. Spending slower. 7,042 rupees under steady pace. '
          'At this pace about 9,300 rupees spare.',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Food: 19,010 rupees, 69%'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the current cycle has no Later, and no earlier cycle means no Earlier', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey<String>('earlier-cycle')));
      await tester.tap(find.byKey(const ValueKey<String>('later-cycle')));
      await tester.pumpAndSettle();
      expect(find.text('October'), findsOneWidget);
      expect(services.haptics.events, isEmpty);
    });

    testWidgets('Earlier shows September; Later comes back', (WidgetTester tester) async {
      trackSeptember();
      await pump(tester);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey<String>('earlier-cycle')));
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      expect(find.text('September'), findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey<String>('later-cycle')));
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      expect(find.text('October'), findsOneWidget);
    });

    testWidgets('a past cycle with nothing spent drops "yet"', (WidgetTester tester) async {
      trackSeptember();
      services.ledger.entries.removeWhere((Entry e) => e.id == 202);
      await pump(tester);
      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey<String>('earlier-cycle')));
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      expect(find.text('Nothing was spent in September.'), findsOneWidget);
    });

    testWidgets('See every entry opens the cycle unfiltered', (WidgetTester tester) async {
      await pump(tester);
      await tester.ensureVisible(find.byKey(const ValueKey<String>('see-every-entry')));
      await tester.tap(find.byKey(const ValueKey<String>('see-every-entry')));
      expect(opened, <(PayCycle, Option<int>)>[(_october, const Option<int>.none())]);
    });

    testWidgets('insights: Food up from last month opens Food\'s entries; the offer saves limits', (WidgetTester tester) async {
      trackSeptember();
      await pump(tester);
      await scrollToInsights(tester);
      expect(find.text('Worth knowing'), findsOneWidget);
      expect(find.text('Food spending is ₹17,010 more than in September.'), findsOneWidget);
      await tester.ensureVisible(find.text('See Food entries'));
      await tester.pump();
      await tester.tap(find.text('See Food entries'));
      expect(opened, <(PayCycle, Option<int>)>[(_october, const Option<int>.of(SeedCategoryIds.food))]);
      await tester.ensureVisible(find.text('Use these limits'));
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.text('Use these limits'));
        await pumpEventQueue();
      });
      await tester.pump();
      expect(services.categories.savedLimits, hasLength(1));
    });

    testWidgets('See every entry lives in Where it went\'s title row, not at the end of the page', (WidgetTester tester) async {
      trackSeptember();
      await pump(tester);
      await scrollToInsights(tester);
      final Finder link = find.byKey(const ValueKey<String>('see-every-entry'));
      expect(link, findsOneWidget);
      expect(find.descendant(of: find.byType(WhereItWentCard), matching: link), findsOneWidget);
      expect(tester.getTopLeft(link).dy, lessThan(tester.getTopLeft(find.byType(InsightsCard)).dy));
    });

    testWidgets('See every entry is on the first screen of a phone', (WidgetTester tester) async {
      trackSeptember();
      await pump(tester);
      expect(tester.getBottomLeft(find.byKey(const ValueKey<String>('see-every-entry'))).dy, lessThan(TestWindows.phone.height));
    });

    testWidgets('a failed limits save says so', (WidgetTester tester) async {
      trackSeptember();
      await pump(tester);
      services.categories.failure = DatabaseFailure('locked');
      await scrollToInsights(tester);
      await tester.ensureVisible(find.text('Use these limits'));
      await tester.pump();
      await tester.runAsync(() async {
        await tester.tap(find.text('Use these limits'));
        await pumpEventQueue();
      });
      await tester.pump();
      expect(find.text("Couldn't save. Try again."), findsOneWidget);
    });

    testWidgets('nothing spent: one sentence, no chart or rows', (WidgetTester tester) async {
      services.ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.spent);
      await pump(tester);
      expect(find.text('Nothing spent in October yet.'), findsOneWidget);
      expect(find.byType(WhereItWentCard), findsNothing);
      expect(find.byKey(const ValueKey<String>('see-every-entry')), findsOneWidget);
    });

    testWidgets('nothing spent: See every entry sits inside the card and opens the cycle', (WidgetTester tester) async {
      services.ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.spent);
      await pump(tester);
      final Finder link = find.byKey(const ValueKey<String>('see-every-entry'));
      expect(find.descendant(of: find.byType(SpendsCard), matching: link), findsOneWidget);
      await tester.tap(link);
      expect(opened, <(PayCycle, Option<int>)>[(_october, const Option<int>.none())]);
    });

    testWidgets('no entries at all: the sentence only, no link to an empty list', (WidgetTester tester) async {
      services.ledger.entries.clear();
      await pump(tester);
      expect(find.text('Nothing spent in October yet.'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('see-every-entry')), findsNothing);
    });

    testWidgets('nothing spent: TalkBack reads the link with the cycle', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      services.ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.spent);
      await pump(tester);
      expect(find.bySemanticsLabel('Every entry in October'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('nothing spent: the blank-bill picture sits in the gap under the card', (WidgetTester tester) async {
      services.ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.spent);
      await pump(tester);
      final Finder picture = find.byType(Image);
      expect(find.byType(SpendsEmptyIllustration), findsOneWidget);
      expect(picture, findsOneWidget);
      expect(tester.getTopLeft(picture).dy, greaterThan(tester.getBottomLeft(find.byType(SpendsCard)).dy));
      expect(tester.getBottomLeft(picture).dy, lessThanOrEqualTo(TestWindows.phone.height));
    });

    testWidgets('a cycle with spending has no picture', (WidgetTester tester) async {
      await pump(tester);
      expect(find.byType(SpendsEmptyIllustration), findsNothing);
    });

    for (final (String name, Size size, double scale) in <(String, Size, double)>[
      ('a 320dp phone at 2× text', TestWindows.smallPhone, 2),
      ('a phone in landscape', TestWindows.phoneLandscape, 1.5),
      ('a tablet', TestWindows.tablet, 1),
    ]) {
      testWidgets('nothing spent lays out without overflow or scrolling on $name', (WidgetTester tester) async {
        services.ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.spent);
        await pump(tester, size: size, textScale: scale);
        expect(tester.takeException(), isNull);
        expect(tester.state<ScrollableState>(find.byType(Scrollable).first).position.maxScrollExtent, 0);
      });
    }

    testWidgets('no income: the total shows without a chart', (WidgetTester tester) async {
      services.ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.got);
      await pump(tester);
      expect(find.text('Spending slower'), findsNothing);
      expect(find.textContaining('₹27,570'), findsOneWidget);
    });

    testWidgets('a failed load says so and Try again reloads', (WidgetTester tester) async {
      services.ledger.failure = DatabaseFailure('locked');
      await pump(tester);
      expect(find.text("Couldn't open this."), findsOneWidget);
      services.ledger.failure = null;
      await tester.runAsync(() async {
        await tester.tap(find.text('Try again'));
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      expect(find.byType(PaceCard), findsOneWidget);
    });

    group('alignment', () {
      testWidgets('the switcher sits flush with the cards\' right edge', (WidgetTester tester) async {
        await pump(tester);
        final Finder switcher = find.ancestor(of: find.text('October'), matching: find.byType(Container)).last;
        expect(tester.getTopRight(switcher).dx, tester.getTopRight(find.byType(PaceCard)).dx);
      });

      testWidgets('the title and cards share one left edge', (WidgetTester tester) async {
        await pump(tester);
        final double edge = tester.getTopLeft(find.byType(PaceCard)).dx;
        expect(tester.getTopLeft(find.text('Spends')).dx, edge);
        expect(tester.getTopLeft(find.byType(WhereItWentCard)).dx, edge);
      });

      testWidgets('nothing spent: See every entry ends on the card\'s content edge, as See all does', (WidgetTester tester) async {
        services.ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.spent);
        await pump(tester);
        final double contentEdge = tester.getTopRight(find.byType(SpendsCard)).dx - 20;
        expect(tester.getTopRight(find.text('See every entry')).dx, contentEdge);
      });

      testWidgets('Where it went\'s title row is one 48dp See all target tall, as on Home', (WidgetTester tester) async {
        await pump(tester);
        final double top = tester.getTopLeft(find.byType(WhereItWentCard)).dy;
        expect(tester.getTopLeft(find.text('Where it went')).dy - top, closeTo(23, 0.5));
        expect(tester.getTopLeft(find.text('Food')).dy - top, 76);
      });

      testWidgets('card content starts at one inner inset', (WidgetTester tester) async {
        await pump(tester);
        final double inset = tester.getTopLeft(find.byType(PaceCard)).dx + 20;
        expect(tester.getTopLeft(find.text('Spent so far')).dx, inset);
        expect(tester.getTopLeft(find.text('Where it went')).dx, inset);
      });
    });

    group('pace chart height (D135)', () {
      Size chart(WidgetTester tester) => tester.getSize(find.byKey(const ValueKey<String>('pace-chart')));

      testWidgets('is 0.6 of the card width on a phone', (WidgetTester tester) async {
        await pump(tester);
        expect(chart(tester).height, closeTo(chart(tester).width * 0.6, 0.01));
        expect(chart(tester).height, inInclusiveRange(168, 216));
      });

      testWidgets('never drops below 168 on a 320dp phone', (WidgetTester tester) async {
        await pump(tester, size: TestWindows.smallPhone);
        expect(chart(tester).height, 168);
      });

      testWidgets('stops at 216 on a tablet', (WidgetTester tester) async {
        await pump(tester, size: TestWindows.tablet);
        expect(chart(tester).height, 216);
      });
    });

    final List<(String, Size, double, ThemeMode)> windows = <(String, Size, double, ThemeMode)>[
      ('a 320dp phone at 2× text', TestWindows.smallPhone, 2, ThemeMode.light),
      ('a phone at 1.5× text in dark mode', TestWindows.phone, 1.5, ThemeMode.dark),
      ('a phone in landscape', TestWindows.phoneLandscape, 1, ThemeMode.light),
      ('a tablet', TestWindows.tablet, 1, ThemeMode.light),
    ];
    for (final (String name, Size size, double scale, ThemeMode theme) in windows) {
      testWidgets('lays out without overflow on $name', (WidgetTester tester) async {
        trackSeptember();
        await pump(tester, size: size, textScale: scale, theme: theme);
        expect(tester.takeException(), isNull);
      });
    }

    for (final (String name, Size size, double scale) in <(String, Size, double)>[
      ('a 320dp phone at 2× text', TestWindows.smallPhone, 2),
      ('a phone in landscape', TestWindows.phoneLandscape, 1.5),
      ('an unfolded foldable', TestWindows.foldableUnfolded, 1.5),
      ('a tablet', TestWindows.tablet, 1.5),
    ]) {
      testWidgets('the pace legend wraps inside the card on $name', (WidgetTester tester) async {
        await pump(tester, size: size, textScale: scale);
        final Rect card = tester.getRect(find.byType(PaceCard));
        final Rect verdict = tester.getRect(find.text('Spending slower'));
        expect(tester.takeException(), isNull);
        expect(verdict.left, greaterThanOrEqualTo(card.left));
        expect(verdict.right, lessThanOrEqualTo(card.right));
      });
    }

    testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      trackSeptember();
      await pump(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('the Ask AI card sits above the pace card and opens Ask AI for the cycle', (WidgetTester tester) async {
      await pump(tester);
      final Finder card = find.byKey(const ValueKey<String>('ask-ai-card'));
      expect(tester.getTopLeft(card).dy, lessThan(tester.getTopLeft(find.byType(PaceCard)).dy));
      await tester.tap(card);
      expect(asked, <PayCycle>[_october]);
    });

    testWidgets('an empty cycle has no Ask AI card', (WidgetTester tester) async {
      services.ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.spent);
      await pump(tester);
      expect(find.byKey(const ValueKey<String>('ask-ai-card')), findsNothing);
    });
  });

  group('SpendsPage savings (D120)', () {
    testWidgets('the Spent · Saved line sits above Where it went', (WidgetTester tester) async {
      services.recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.rd];
      services.ledger.entries.add(Entry(
          id: 50,
          amount: Money.fromMajor(5000),
          kind: EntryKind.saved,
          categoryId: SeedCategoryIds.saved,
          date: const CalendarDate(2026, 10, 10),
          createdAt: WorkedExample.now,
          recurringId: 4,
          note: 'RD',
        ));
      await pump(tester);
      final Finder line = find.text('Spent ₹27,570 · Saved ₹5,000');
      expect(line, findsOneWidget);
      expect(tester.getTopLeft(line).dy, lessThan(tester.getTopLeft(find.text('Where it went')).dy));
    });

    testWidgets('the Spent · Saved line starts on the cards\' outer edge', (WidgetTester tester) async {
      services.recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.rd];
      services.ledger.entries.add(Entry(
          id: 50,
          amount: Money.fromMajor(5000),
          kind: EntryKind.saved,
          categoryId: SeedCategoryIds.saved,
          date: const CalendarDate(2026, 10, 10),
          createdAt: WorkedExample.now,
          recurringId: 4,
          note: 'RD',
        ));
      await pump(tester);
      expect(tester.getTopLeft(find.text('Spent ₹27,570 · Saved ₹5,000')).dx, tester.getTopLeft(find.byType(WhereItWentCard)).dx);
    });

    testWidgets('no saves: no line', (WidgetTester tester) async {
      await pump(tester);
      expect(find.textContaining('Saved'), findsNothing);
    });
  });
}
