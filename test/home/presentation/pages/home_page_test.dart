import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/design/app_icon.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/widgets/day_blocks/day_blocks.dart';
import 'package:expense_tracker/home/home.dart';
import 'package:expense_tracker/home/presentation/widgets/due_soon_note.dart';
import 'package:expense_tracker/home/presentation/widgets/hero_card.dart';
import 'package:expense_tracker/home/presentation/widgets/home_header.dart';
import 'package:expense_tracker/home/presentation/widgets/saved_yesterday_note.dart';
import 'package:expense_tracker/home/presentation/widgets/today_list.dart';
import 'package:expense_tracker/home/presentation/widgets/today_row.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeServices services;
  late HomeCubit cubit;
  late List<Object> calls;

  setUp(() {
    services = FakeServices();
    cubit = services.homeCubit();
    calls = <Object>[];
  });

  tearDown(() async {
    await cubit.close();
    await services.dispose();
  });

  Future<void> pump(WidgetTester tester, {bool load = true, Size size = TestWindows.phone, double textScale = 1, ThemeMode theme = ThemeMode.light}) async {
    if (load) {
      await tester.runAsync(cubit.load);
    }
    await pumpApp(
      tester,
      BlocProvider<HomeCubit>.value(
        value: cubit,
        child: Scaffold(
          body: HomePage(
            onAdd: (EntryKind kind) => calls.add(kind),
            onEdit: (Entry entry) => calls.add(entry),
            onOpenSettings: () => calls.add('settings'),
          ),
        ),
      ),
      size: size,
      textScale: textScale,
      themeMode: theme,
    );
  }

  group('HomePage (FR-HO)', () {
    testWidgets('loading shows the hero card without a number', (WidgetTester tester) async {
      await pump(tester, load: false);
      expect(find.text('Safe to spend today'), findsOneWidget);
      expect(find.textContaining('₹'), findsNothing);
    });

    testWidgets('shows the worked example: date, ₹1,430, payday flag, range line and today\'s rows', (WidgetTester tester) async {
      await pump(tester);
      expect(find.text('Mon, 26 Oct'), findsOneWidget);
      expect(find.text('₹1,430'), findsOneWidget);
      expect(find.text('4 Nov'), findsOneWidget);
      expect(find.text('9 days to payday'), findsOneWidget);
      expect(find.textContaining('Lasts till payday'), findsOneWidget);
      expect(find.text('Chai & samosa'), findsOneWidget);
      expect(find.text('₹420'), findsOneWidget);
    });

    testWidgets('TalkBack reads the hero as one sentence (FR-HO-7)', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      expect(
        find.bySemanticsLabel(RegExp('^Safe to spend today: 1,430 rupees. 9 days to payday. Lasts till payday, about 9,300 rupees spare.')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('nudges about the soonest bill, read with spoken amounts (FR-HO-3)', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      expect(find.text('Electricity ₹1,200 goes out in 3 days'), findsOneWidget);
      expect(find.bySemanticsLabel('Electricity 1,200 rupees goes out in 3 days'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a bill due tomorrow says tomorrow', (WidgetTester tester) async {
      services.recurring.rules = <RecurringRule>[
        WorkedExample.salary,
        WorkedExample.electricity.copyWith(
          schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 9, 27)),
          nextDue: const CalendarDate(2026, 10, 27),
        ),
      ];
      await pump(tester);
      expect(find.text('Electricity ₹1,200 goes out tomorrow'), findsOneWidget);
    });

    testWidgets('no nudge when no bill goes out within 5 days', (WidgetTester tester) async {
      services.recurring.rules = <RecurringRule>[WorkedExample.salary, WorkedExample.rent];
      await pump(tester);
      expect(find.textContaining('goes out'), findsNothing);
    });

    testWidgets('the nudge shows under the no-income card too', (WidgetTester tester) async {
      services.recurring.rules = <RecurringRule>[WorkedExample.electricity];
      services.ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.got);
      await pump(tester);
      expect(find.text('Add money you got this month'), findsOneWidget);
      expect(find.text('Electricity ₹1,200 goes out in 3 days'), findsOneWidget);
    });

    group('alignment', () {
      for (final (String name, Size size, double scale) in <(String, Size, double)>[
        ('a phone', TestWindows.phone, 1),
        ('a 320dp phone at 1.5× text', TestWindows.smallPhone, 1.5),
      ]) {
        testWidgets('Settings sits flush with the cards\' right edge on $name', (WidgetTester tester) async {
          await pump(tester, size: size, textScale: scale);
          expect(
            tester.getTopRight(find.byKey(const ValueKey<String>('open-settings'))).dx,
            tester.getTopRight(find.byType(HeroCard)).dx,
          );
        });
      }

      testWidgets('the wordmark starts on the cards\' left edge', (WidgetTester tester) async {
        await pump(tester);
        expect(tester.getTopLeft(find.byType(HomeHeader)).dx, tester.getTopLeft(find.byType(HeroCard)).dx);
      });

      testWidgets('hero, nudge and Today list content share one left inset', (WidgetTester tester) async {
        await pump(tester);
        final double hero = tester.getTopLeft(find.text('Safe to spend today')).dx;
        expect(tester.getTopLeft(find.descendant(of: find.byType(TodayList), matching: find.text('Today'))).dx, hero);
        expect(tester.getTopLeft(find.descendant(of: find.byType(DueSoonNote), matching: find.byType(AppIcon))).dx, hero);
        expect(tester.getTopLeft(find.descendant(of: find.byType(SavedYesterdayNote), matching: find.byType(AppIcon))).dx, hero);
      });

      testWidgets('Today list rows start on the hero\'s content edge', (WidgetTester tester) async {
        await pump(tester);
        final Finder well = find.descendant(of: find.byType(TodayRow).first, matching: find.byType(Container)).first;
        expect(tester.getTopLeft(well).dx, tester.getTopLeft(find.text('Safe to spend today')).dx);
      });

      testWidgets('"N days to payday" ends where the last block ends', (WidgetTester tester) async {
        await pump(tester);
        expect(tester.getTopRight(find.text('9 days to payday')).dx, tester.getTopRight(find.byType(DayBlocks)).dx);
      });

      testWidgets('the payday flag sits centred in a 44dp column at the card\'s content edge', (WidgetTester tester) async {
        await pump(tester);
        final double flagCentre = tester.getCenter(find.text('4 Nov')).dx;
        final double cardContentRight = tester.getTopRight(find.byType(HeroCard)).dx - 20;
        expect(flagCentre, closeTo(cardContentRight - 22, 0.5));
      });
    });

    testWidgets('Settings opens from the header', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      expect(calls, <Object>['settings']);
    });

    testWidgets('tapping a row edits it (FR-AD-8)', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.text('Chai & samosa'));
      expect(calls.single, WorkedExample.entries[3]);
    });

    testWidgets('swiping deletes at once and Undo brings it back (BR-10)', (WidgetTester tester) async {
      await pump(tester);
      await tester.drag(find.text('Chai & samosa'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Chai & samosa'), findsNothing);
      expect(find.text('Deleted ₹60'), findsOneWidget);
      expect(services.haptics.events, contains('threshold'));
      await tester.tap(find.text('Undo'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.text('Chai & samosa'), findsOneWidget);
    });

    testWidgets('TalkBack users can delete a row without swiping', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      final SemanticsNode row = tester.getSemantics(find.text('Chai & samosa'));
      expect(row.getSemanticsData().customSemanticsActionIds, isNotEmpty);
      handle.dispose();
    });

    testWidgets('an empty day says what to do', (WidgetTester tester) async {
      services.ledger.entries.removeWhere((Entry e) => e.date == WorkedExample.today);
      await pump(tester);
      expect(find.text('Nothing spent today. Tap Add when you do.'), findsOneWidget);
    });

    testWidgets('a Got entry shows with a plus', (WidgetTester tester) async {
      await services.ledger
          .add(EntryDraft(amount: Money.fromMajor(500), kind: EntryKind.got, categoryId: 10, date: WorkedExample.today))
          .run();
      await pump(tester);
      expect(find.text('+₹500'), findsOneWidget);
    });

    testWidgets('no income asks for money in and opens Add on Got (E10)', (WidgetTester tester) async {
      services.recurring.rules = <RecurringRule>[];
      services.ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.got);
      await pump(tester);
      expect(find.text('Add money you got this month'), findsOneWidget);
      await tester.tap(find.text('Add money'));
      expect(calls, <Object>[EntryKind.got]);
    });

    testWidgets('a failed load says so and Try again reloads', (WidgetTester tester) async {
      services.ledger.failure = DatabaseFailure('locked');
      await pump(tester);
      expect(find.text("Couldn't load your money."), findsOneWidget);
      services.ledger.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.text('₹1,430'), findsOneWidget);
    });

    testWidgets('over today, in dark mode: ₹0 with the overspend in words (BR-5)', (WidgetTester tester) async {
      await services.ledger
          .add(EntryDraft(amount: Money.fromMajor(2450), kind: EntryKind.spent, categoryId: 3, date: WorkedExample.today))
          .run();
      await pump(tester, theme: ThemeMode.dark);
      expect(find.text('₹0'), findsOneWidget);
      expect(find.text('₹1,020 over today'), findsOneWidget);
      expect(find.text('Each day after: ₹1,722'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    group('This week (FR-HO-2)', () {
      testWidgets('tapping the hero flips to this week and back', (WidgetTester tester) async {
        await pump(tester);
        await tester.tap(find.byType(HeroCard));
        await tester.pumpAndSettle();
        expect(find.text('Safe to spend this week'), findsOneWidget);
        expect(find.text('₹12,530'), findsOneWidget);
        expect(find.text('9 days to payday'), findsOneWidget, reason: 'the blocks stay on today');
        await tester.tap(find.byType(HeroCard));
        await tester.pumpAndSettle();
        expect(find.text('Safe to spend today'), findsOneWidget);
        expect(find.text('₹1,430'), findsOneWidget);
      });

      testWidgets('TalkBack can flip it too, and hears what a tap will do', (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pump(tester);
        final Finder hero = find.bySemanticsLabel(RegExp('^Safe to spend today'));
        expect(tester.getSemantics(hero), isSemantics(hasTapAction: true, onTapHint: 'show this week'));
        tester.semantics.tap(find.semantics.byLabel(RegExp('^Safe to spend today')));
        await tester.pumpAndSettle();
        final Finder week = find.bySemanticsLabel(RegExp('^Safe to spend this week: 12,530 rupees'));
        expect(week, findsOneWidget);
        expect(tester.getSemantics(week), isSemantics(onTapHint: 'show today'));
        handle.dispose();
      });
    });

    group('saved yesterday (BR-8)', () {
      testWidgets('nothing spent yesterday: the note shows the saving and what each day gained', (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pump(tester);
        expect(find.text('You saved ₹1,665 yesterday, so every day got ₹185 more.'), findsOneWidget);
        expect(find.bySemanticsLabel('You saved 1,665 rupees yesterday, so every day got 185 rupees more.'), findsOneWidget);
        handle.dispose();
      });

      testWidgets('under ₹1 more a day: only the saving is mentioned', (WidgetTester tester) async {
        await services.ledger
            .add(EntryDraft(amount: Money.fromMajor(1660), kind: EntryKind.spent, categoryId: 1, date: const CalendarDate(2026, 10, 25)))
            .run();
        await pump(tester);
        expect(find.text('You saved ₹5 yesterday.'), findsOneWidget);
      });

      testWidgets('no note after overspending yesterday', (WidgetTester tester) async {
        await services.ledger
            .add(EntryDraft(amount: Money.fromMajor(2000), kind: EntryKind.spent, categoryId: 1, date: const CalendarDate(2026, 10, 25)))
            .run();
        await pump(tester);
        expect(find.byType(SavedYesterdayNote), findsNothing);
      });
    });

    final List<(String, Size, double)> windows = <(String, Size, double)>[
      ('a 320dp phone at 2× text', TestWindows.smallPhone, 2),
      ('a phone at 1.5× text (E12)', TestWindows.phone, 1.5),
      ('a split-screen window (E18)', const Size(412, 400), 1),
      ('a phone in landscape', TestWindows.phoneLandscape, 1),
    ];
    for (final (String name, Size size, double scale) in windows) {
      testWidgets('lays out without overflow on $name', (WidgetTester tester) async {
        await pump(tester, size: size, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
