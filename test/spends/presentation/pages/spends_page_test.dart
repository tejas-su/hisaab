import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/spends/presentation/widgets/insights_card.dart';
import 'package:expense_tracker/spends/presentation/widgets/pace_card.dart';
import 'package:expense_tracker/spends/presentation/widgets/where_it_went_card.dart';
import 'package:expense_tracker/spends/spends.dart';
import 'package:flutter/material.dart';
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

  setUp(() {
    services = FakeServices();
    bloc = services.spendsBloc();
    opened = <(PayCycle, Option<int>)>[];
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
          ),
        ),
      ),
      size: size,
      textScale: textScale,
      themeMode: theme,
    );
  }

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
      expect(find.text('Below pace'), findsOneWidget);
      expect(find.text('Where it went'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('69%'), findsOneWidget);
      expect(find.text('₹19,010'), findsOneWidget);
      expect(find.byType(InsightsCard), findsNothing);
    });

    testWidgets('TalkBack reads the pace card as one sentence', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      expect(find.bySemanticsLabel('27,570 rupees spent so far of 45,000 rupees. Below pace.'), findsOneWidget);
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

    testWidgets('See every entry opens the cycle unfiltered', (WidgetTester tester) async {
      await pump(tester);
      await tester.ensureVisible(find.byKey(const ValueKey<String>('see-every-entry')));
      await tester.tap(find.byKey(const ValueKey<String>('see-every-entry')));
      expect(opened, <(PayCycle, Option<int>)>[(_october, const Option<int>.none())]);
    });

    testWidgets('insights: Food up from last month opens Food\'s entries; the offer saves limits', (WidgetTester tester) async {
      trackSeptember();
      await pump(tester);
      expect(find.text('Worth knowing'), findsOneWidget);
      expect(find.text('Food is up ₹17,010 from last month.'), findsOneWidget);
      await tester.ensureVisible(find.text('See entries'));
      await tester.tap(find.text('See entries'));
      expect(opened, <(PayCycle, Option<int>)>[(_october, const Option<int>.of(SeedCategoryIds.food))]);
      await tester.ensureVisible(find.text('Use these limits'));
      await tester.runAsync(() async {
        await tester.tap(find.text('Use these limits'));
        await pumpEventQueue();
      });
      await tester.pump();
      expect(services.categories.savedLimits, hasLength(1));
    });

    testWidgets('a failed limits save says so', (WidgetTester tester) async {
      trackSeptember();
      await pump(tester);
      services.categories.failure = DatabaseFailure('locked');
      await tester.ensureVisible(find.text('Use these limits'));
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

    testWidgets('no income: the total shows without a chart', (WidgetTester tester) async {
      services.ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.got);
      await pump(tester);
      expect(find.text('Below pace'), findsNothing);
      expect(find.textContaining('₹27,570'), findsOneWidget);
    });

    testWidgets('a failed load says so and Try again reloads', (WidgetTester tester) async {
      services.ledger.failure = DatabaseFailure('locked');
      await pump(tester);
      expect(find.text("Couldn't load your money."), findsOneWidget);
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

      testWidgets('the title, cards and See every entry share one left edge', (WidgetTester tester) async {
        await pump(tester);
        final double edge = tester.getTopLeft(find.byType(PaceCard)).dx;
        expect(tester.getTopLeft(find.text('Spends')).dx, edge);
        expect(tester.getTopLeft(find.byType(WhereItWentCard)).dx, edge);
        expect(tester.getTopLeft(find.byKey(const ValueKey<String>('see-every-entry'))).dx, edge);
      });

      testWidgets('card content starts at one inner inset', (WidgetTester tester) async {
        await pump(tester);
        final double inset = tester.getTopLeft(find.byType(PaceCard)).dx + 20;
        expect(tester.getTopLeft(find.text('Spent so far')).dx, inset);
        expect(tester.getTopLeft(find.text('Where it went')).dx, inset);
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

    testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      trackSeptember();
      await pump(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
