import 'package:expense_tracker/core/widgets/week_bars/week_bars.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/design/app_icon.dart';
import 'package:expense_tracker/core/design/hisaab_colors.dart';
import 'package:expense_tracker/core/widgets/hisaab_chip.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/core/widgets/days_rail/days_rail.dart';
import 'package:expense_tracker/home/home.dart';
import 'package:expense_tracker/home/presentation/widgets/due_soon_row.dart';
import 'package:expense_tracker/home/presentation/widgets/hero_card.dart';
import 'package:expense_tracker/home/presentation/widgets/home_header.dart';
import 'package:expense_tracker/home/presentation/widgets/saved_yesterday_note.dart';
import 'package:expense_tracker/home/presentation/widgets/today_list.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeServices services;
  late HomeBloc bloc;
  late List<Object> calls;

  setUp(() {
    services = FakeServices();
    bloc = services.homeBloc();
    calls = <Object>[];
  });

  tearDown(() async {
    await bloc.close();
    await services.dispose();
  });

  Future<void> pump(
    WidgetTester tester, {
    bool load = true,
    Size size = TestWindows.phone,
    double textScale = 1,
    ThemeMode theme = ThemeMode.light,
    bool links = false,
  }) async {
    if (load) {
      await tester.runAsync(() => bloc.dispatch(const HomeLoadRequested()));
    }
    await pumpApp(
      tester,
      BlocProvider<HomeBloc>.value(
        value: bloc,
        child: Scaffold(
          body: HomePage(
            onAdd: (EntryKind kind) => calls.add(kind),
            onEdit: (Entry entry) => calls.add(entry),
            onOpenSettings: () => calls.add('settings'),
            onOpenBill: calls.add,
            onSeeAll: links ? calls.add : null,
            onSeeWhereItWent: links ? () => calls.add('spends') : null,
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

    testWidgets('tapping the nudge opens its bill (D118)', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.byType(DueSoonRow));
      expect(calls, <Object>[WorkedExample.electricity]);
    });

    testWidgets('deleting a saving from its sheet offers Undo with its name (D120)', (WidgetTester tester) async {
      services.recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.rd];
      await pump(tester);
      await tester.runAsync(() => bloc.dispatch(HomeBillDeleteRequested(WorkedExample.rd)));
      await tester.settle();
      expect(find.text('Deleted RD'), findsOneWidget);
    });

    testWidgets('a bill deleted from its sheet offers Undo, which brings it back (D118)', (WidgetTester tester) async {
      await pump(tester);
      await tester.runAsync(() => bloc.dispatch(HomeBillDeleteRequested(WorkedExample.electricity)));
      await tester.settle();
      expect(find.text('Deleted Electricity'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.settle();
      expect(services.recurring.rules, contains(WorkedExample.electricity));
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

      testWidgets('Settings draws a 40dp well, flush with the cards, inside a 48dp tap target', (WidgetTester tester) async {
        await pump(tester);
        final Finder well = find.byKey(const ValueKey<String>('open-settings-well'));
        expect(tester.getSize(find.byKey(const ValueKey<String>('open-settings'))), const Size(48, 48));
        expect(tester.getSize(well), const Size(40, 40));
        expect(tester.getTopRight(well).dx, tester.getTopRight(find.byType(HeroCard)).dx);
      });

      testWidgets('the wordmark starts on the cards\' left edge', (WidgetTester tester) async {
        await pump(tester);
        expect(tester.getTopLeft(find.byType(HomeHeader)).dx, tester.getTopLeft(find.byType(HeroCard)).dx);
      });

      testWidgets('hero, nudge and Today list content share one left inset', (WidgetTester tester) async {
        await pump(tester);
        final double hero = tester.getTopLeft(find.text('Safe to spend today')).dx;
        expect(tester.getTopLeft(find.descendant(of: find.byType(TodayList), matching: find.text('Today'))).dx, hero);
        expect(tester.getTopLeft(find.descendant(of: find.byType(DueSoonRow), matching: find.byType(AppIcon)).first).dx, hero);
        expect(tester.getTopLeft(find.descendant(of: find.byType(SavedYesterdayNote), matching: find.byType(AppIcon))).dx, hero);
      });

      testWidgets('Today list rows start on the hero\'s content edge', (WidgetTester tester) async {
        await pump(tester);
        final Finder well = find.descendant(of: find.byType(EntryRow).first, matching: find.byType(Container)).first;
        expect(tester.getTopLeft(well).dx, tester.getTopLeft(find.text('Safe to spend today')).dx);
      });

      testWidgets('"N days to payday" ends where the rail\'s dots end, a gap before the flag (D114)', (WidgetTester tester) async {
        await pump(tester);
        final Finder flag = find.descendant(of: find.byType(DaysRail), matching: find.byType(AppIcon));
        expect(tester.getTopRight(find.text('9 days to payday')).dx, tester.getTopLeft(flag).dx - DaysRail.flagGap);
      });

      testWidgets('the payday flag\'s date ends on the card\'s content edge (D114)', (WidgetTester tester) async {
        await pump(tester);
        final double cardContentRight = tester.getTopRight(find.byType(HeroCard)).dx - 20;
        expect(tester.getTopRight(find.text('4 Nov')).dx, cardContentRight);
      });
    });

    testWidgets('the Settings well is a control on the page and steps to sunk while pressed (D97, D100)', (WidgetTester tester) async {
      await pump(tester);
      final Finder well = find.byKey(const ValueKey<String>('open-settings-well'));
      Color? fill() => (tester.widget<Container>(well).decoration! as ShapeDecoration).color;
      expect(fill(), HisaabColors.light.control);
      final TestGesture press = await tester.startGesture(tester.getCenter(well));
      // why: the header scrolls with the page, so tap-down waits for the press timeout.
      await tester.pump(kPressTimeout);
      expect(fill(), HisaabColors.light.sunk);
      await press.up();
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
      await tester.settle();
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
        await tester.settle();
        expect(find.text('Safe to spend this week'), findsOneWidget);
        expect(find.text('₹12,530'), findsOneWidget);
        expect(find.byType(WeekBars), findsOneWidget, reason: 'the weekday bars take today\'s bar\'s place (BR-6a)');
        expect(find.text('9 days to payday'), findsOneWidget, reason: 'the days rail stays in both modes (D114)');
        await tester.tap(find.byType(HeroCard));
        await tester.settle();
        expect(find.text('Safe to spend today'), findsOneWidget);
        expect(find.text('₹1,430'), findsOneWidget);
      });

      testWidgets('TalkBack can flip it too, and hears what a tap will do', (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pump(tester);
        final Finder hero = find.bySemanticsLabel(RegExp('^Safe to spend today'));
        expect(tester.getSemantics(hero), isSemantics(hasTapAction: true, onTapHint: 'show this week'));
        tester.semantics.tap(find.semantics.byLabel(RegExp('^Safe to spend today')));
        await tester.settle();
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
        expect(find.text('Yesterday was ₹1,665 under its share, so every day got ₹185 more.'), findsOneWidget);
        expect(find.bySemanticsLabel('Yesterday was 1,665 rupees under its share, so every day got 185 rupees more.'), findsOneWidget);
        handle.dispose();
      });

      testWidgets('under ₹1 more a day: only the saving is mentioned', (WidgetTester tester) async {
        await services.ledger
            .add(EntryDraft(amount: Money.fromMajor(1660), kind: EntryKind.spent, categoryId: 1, date: const CalendarDate(2026, 10, 25)))
            .run();
        await pump(tester);
        expect(find.text('Yesterday was ₹5 under its share.'), findsOneWidget);
      });

      testWidgets('no note after overspending yesterday', (WidgetTester tester) async {
        await services.ledger
            .add(EntryDraft(amount: Money.fromMajor(2000), kind: EntryKind.spent, categoryId: 1, date: const CalendarDate(2026, 10, 25)))
            .run();
        await pump(tester);
        expect(find.byType(SavedYesterdayNote), findsNothing);
      });
    });

    group('links out (FR-HO-4, FR-HO-5)', () {
      Future<void> overspend() =>
          services.ledger.add(EntryDraft(amount: Money.fromMajor(2450), kind: EntryKind.spent, categoryId: 3, date: WorkedExample.today)).run();

      testWidgets('See all opens the cycle\'s entries and ends on the card\'s content edge', (WidgetTester tester) async {
        await pump(tester, links: true);
        final Finder seeAll = find.byKey(const ValueKey<String>('see-all'));
        expect(tester.getTopRight(seeAll).dx, tester.getTopRight(find.byType(TodayList)).dx - 20);
        await tester.tap(seeAll);
        expect(calls.single, isA<PayCycle>());
      });

      testWidgets('without the links, See all is hidden', (WidgetTester tester) async {
        await pump(tester);
        expect(find.byKey(const ValueKey<String>('see-all')), findsNothing);
      });

      testWidgets('over today: a calm card spreads the overspend and offers See where it went', (WidgetTester tester) async {
        await overspend();
        await pump(tester, links: true);
        expect(find.text('It happens. The ₹1,020 is spread across the next 8 days, so each one is a little smaller.'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey<String>('see-where-it-went')));
        expect(calls, <Object>['spends']);
      });

      testWidgets('the over card’s chip sits on the card, so it keeps the hairline step (D100)', (WidgetTester tester) async {
        await overspend();
        await pump(tester, links: true);
        expect(tester.widget<HisaabChip>(find.byKey(const ValueKey<String>('see-where-it-went'))).onSurface, isTrue);
      });

      testWidgets('over today with one day after: it comes out of tomorrow', (WidgetTester tester) async {
        services.clock.current = DateTime(2026, 11, 2, 10);
        await services.ledger
            .add(EntryDraft(amount: Money.fromMajor(9000), kind: EntryKind.spent, categoryId: 3, date: const CalendarDate(2026, 11, 2)))
            .run();
        await pump(tester);
        expect(find.textContaining('comes out of tomorrow'), findsOneWidget);
      });

      testWidgets('over the cycle: the money is used up until payday', (WidgetTester tester) async {
        await services.ledger
            .add(EntryDraft(amount: Money.fromMajor(17000), kind: EntryKind.spent, categoryId: 3, date: WorkedExample.today))
            .run();
        await pump(tester);
        expect(find.text("It happens. This month's money is used up. It starts again on payday, 4 Nov."), findsOneWidget);
        expect(find.byKey(const ValueKey<String>('see-where-it-went')), findsNothing, reason: 'no link was given');
      });

      testWidgets('on track: no over card', (WidgetTester tester) async {
        await pump(tester, links: true);
        expect(find.byKey(const ValueKey<String>('see-where-it-went')), findsNothing);
        expect(find.textContaining('It happens.'), findsNothing);
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
