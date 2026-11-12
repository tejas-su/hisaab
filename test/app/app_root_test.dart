import 'dart:async';

import 'package:hisaab/add_entry/add_entry.dart';
import 'package:hisaab/app/app_shell.dart';
import 'package:hisaab/app/hisaab_app.dart';
import 'package:hisaab/app/widgets/hisaab_dock.dart';
import 'package:hisaab/app/widgets/startup_failure_view.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/notifications/bill_reminder.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/widgets/days_rail/days_rail.dart';
import 'package:hisaab/core/widgets/hisaab_snackbar_bar.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/home/home.dart';
import 'package:hisaab/home/presentation/widgets/due_soon_row.dart';
import 'package:hisaab/onboarding/onboarding.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:hisaab/spends/spends.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Option;
import 'package:get_it/get_it.dart';

import '../helpers/tooltip_finder.dart';
import '../helpers/fake_services.dart';
import '../helpers/fixtures/habits/chai_habit.dart';
import '../helpers/fixtures/ledger/worked_example.dart';
import '../helpers/pump_app.dart';

void main() {
  late FakeServices services;

  tearDown(() => services.dispose());

  Future<void> boot(WidgetTester tester, FakeServices fakes) async {
    services = fakes;
    await tester.runAsync(loadAppFonts);
    tester.view
      ..physicalSize = TestWindows.phone
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(HisaabApp(getIt: fakes.register(GetIt.asNewInstance())));
    await settle(tester);
  }

  group('AppRoot (FR-ON-1)', () {
    testWidgets('a fresh install opens onboarding', (WidgetTester tester) async {
      await boot(tester, FakeServices(onboardingDone: false, entries: <Entry>[], rules: <RecurringRule>[]));
      expect(find.byType(OnboardingPage), findsOneWidget);
    });

    testWidgets('restoring a backup from onboarding reloads into Home (FR-ON-1, D139)', (WidgetTester tester) async {
      final FakeServices services = FakeServices(onboardingDone: false, entries: <Entry>[], rules: <RecurringRule>[]);
      await boot(tester, services);
      // why: the fake restore writes nothing, so stand in for the restored onboarding flag.
      services.preferences.done = true;

      await tester.tap(find.byKey(const ValueKey<String>('restore-a-backup')));
      await settle(tester);

      expect(services.backups.restores, hasLength(1));
      expect(find.byType(OnboardingPage), findsNothing);
    });

    testWidgets('finishing onboarding lands on Home with the hero assembling', (WidgetTester tester) async {
      await boot(tester, FakeServices(onboardingDone: false, entries: <Entry>[], rules: <RecurringRule>[]));
      for (final String key in <String>['4', '5', '0', '0', '0']) {
        await tester.tap(find.byKey(ValueKey<String>('keypad-$key')));
        await settle(tester);
      }
      await tester.tap(find.text('Next'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('payday-first')));
      await settle(tester);
      await tester.tap(find.text('Skip'));
      await settle(tester);
      expect(find.byType(AppShell), findsOneWidget);
      expect(tester.widget<DaysRail>(find.byType(DaysRail)).assemble, isTrue);
    });

    testWidgets('a returning user goes straight to Home, in en_IN', (WidgetTester tester) async {
      await boot(tester, FakeServices());
      expect(find.byType(AppShell), findsOneWidget);
      expect(Localizations.localeOf(tester.element(find.byType(AppShell))), const Locale('en', 'IN'));
      expect(find.text('₹1,430'), findsOneWidget);
    });

    testWidgets('an unreadable preference shows the startup failure', (WidgetTester tester) async {
      final FakeServices fakes = FakeServices()..preferences.failure = DatabaseFailure('locked');
      await boot(tester, fakes);
      expect(find.byType(StartupFailureView), findsOneWidget);
    });

    testWidgets('the dock\'s Add key opens the tray and a save updates Home', (WidgetTester tester) async {
      await boot(tester, FakeServices());
      await tester.tap(find.byKey(const ValueKey<String>('add-key')));
      await settle(tester);
      expect(find.byType(AddEntryTray), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('keypad-3')));
      await tester.tap(find.byKey(const ValueKey<String>('keypad-0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('add-next')));
      await settle(tester);
      await tester.tap(find.bySemanticsLabel('Food. Save'));
      await settle(tester);
      expect(find.byType(AddEntryTray), findsNothing);
      expect(find.text('₹1,400'), findsOneWidget);
    });

    testWidgets('tapping a row opens the tray prefilled', (WidgetTester tester) async {
      await boot(tester, FakeServices());
      // why: the due-soon row is 56dp tall (D118), which puts this row under the dock on a phone.
      await tester.ensureVisible(find.text('Chai & samosa'));
      await settle(tester);
      await tester.tap(find.text('Chai & samosa'));
      await settle(tester);
      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(find.text('₹60'), findsWidgets);
    });

    testWidgets('Settings opens from Home and goes back', (WidgetTester tester) async {
      await boot(tester, FakeServices());
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await settle(tester);
      expect(find.byType(SettingsPage), findsOneWidget);
      await tester.tap(findTooltip('Back'));
      await settle(tester);
      expect(find.byType(SettingsPage), findsNothing);
    });

    testWidgets('a category added in Settings is a tile the next time Add opens (FR-SE-2, D138)', (WidgetTester tester) async {
      await boot(tester, FakeServices());
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await settle(tester);
      await tester.ensureVisible(find.byKey(const ValueKey<String>('open-categories')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('open-categories')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('add-category')));
      await settle(tester);
      await tester.enterText(find.byKey(const ValueKey<String>('category-name-field')), 'Petrol');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('category-name-save')));
      await settle(tester);
      await tester.tap(findTooltip('Back'));
      await settle(tester);
      await tester.tap(findTooltip('Back'));
      await settle(tester);

      await tester.tap(find.byKey(const ValueKey<String>('add-key')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('keypad-3')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('add-next')));
      await settle(tester);

      expect(find.bySemanticsLabel('Petrol. Save', skipOffstage: false), findsOneWidget);
    });

    testWidgets('a bill added in Settings shows up in Home\'s nudge (FR-SE-1, FR-HO-3)', (WidgetTester tester) async {
      await boot(tester, FakeServices());
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('open-bills')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('add-bill')));
      await settle(tester);
      await tester.enterText(find.byKey(const ValueKey<String>('bill-name')), 'Water');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('bill-next')));
      await settle(tester);
      for (final String key in <String>['3', '0', '0']) {
        await tester.tap(find.byKey(ValueKey<String>('keypad-$key')));
        await tester.pump();
      }
      await tester.tap(find.byKey(const ValueKey<String>('bill-next')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('day-27')));
      await settle(tester);
      expect(find.text('Water'), findsOneWidget, reason: 'back on the bills list');
      await tester.tap(findTooltip('Back'));
      await settle(tester);
      await tester.tap(findTooltip('Back'));
      await settle(tester);
      expect(find.text('Water, ₹300, due tomorrow'), findsOneWidget);
    });

    Future<void> openBills(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('open-bills')));
      await settle(tester);
    }

    testWidgets('tapping a fixed bill opens its bill sheet, not the editor (FR-SE-1 AC-1)', (WidgetTester tester) async {
      await boot(tester, FakeServices());
      await openBills(tester);
      await tester.tap(find.text('Electricity'));
      await settle(tester);
      expect(find.byType(BillSheet), findsOneWidget);
      expect(find.byType(BillEditorPage), findsNothing);
      expect(find.text('Due in 3 days'), findsOneWidget);
    });

    testWidgets('a change in the sheet shows in the list behind it (AC-4)', (WidgetTester tester) async {
      await boot(tester, FakeServices());
      await openBills(tester);
      await tester.tap(find.text('Electricity'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-row-day')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('day-20')));
      await settle(tester);
      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(find.byType(BillSheet), findsNothing);
      expect(find.text('Every month on day 20'), findsOneWidget);
    });

    testWidgets('Delete bill in the sheet deletes it from the list with Undo (AC-6)', (WidgetTester tester) async {
      await boot(tester, FakeServices());
      await openBills(tester);
      await tester.tap(find.text('Electricity'));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-delete')));
      await settle(tester);
      expect(find.byType(BillSheet), findsNothing);
      expect(find.text('Electricity deleted'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(find.text('Electricity'), findsOneWidget);
    });

    testWidgets('Home\'s due-soon row opens the bill sheet; a delete there offers Undo on Home (FR-HO-3)', (WidgetTester tester) async {
      await boot(tester, FakeServices());
      await tester.tap(find.text('Electricity, ₹1,200, due in 3 days'));
      await settle(tester);
      expect(find.byType(BillSheet), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('bill-delete')));
      await settle(tester);
      expect(find.byType(BillSheet), findsNothing);
      expect(find.text('Electricity, ₹1,200, due in 3 days'), findsNothing);
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(find.text('Electricity, ₹1,200, due in 3 days'), findsOneWidget);
    });

    testWidgets('Home reloads when the app resumes (BR-8)', (WidgetTester tester) async {
      await boot(tester, FakeServices());
      await services.ledger
          .add(EntryDraft(amount: Money.fromMajor(30), kind: EntryKind.spent, categoryId: 1, date: services.clock.today()))
          .run();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(services.recurring.postings, isEmpty);
      expect(find.text('₹1,400'), findsOneWidget);
    });

    testWidgets('payday adds the salary at midnight while the app is open (BR-8)', (WidgetTester tester) async {
      final FakeServices fakes = FakeServices();
      fakes.clock.current = DateTime(2026, 11, 3, 23, 59, 30);
      await boot(tester, fakes);
      expect(find.text('Tue, 3 Nov'), findsOneWidget);
      final int before = services.recurring.postings.length;

      services.clock.advance(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 31));
      await settle(tester);

      expect(services.recurring.postings.length, before + 1);
      expect(
        services.recurring.postings.last.occurrences.map((Occurrence o) => (o.rule.label, o.date)),
        contains(('Salary', const CalendarDate(2026, 11, 4))),
      );
      expect(find.text('Wed, 4 Nov'), findsOneWidget);
    });
  });

  group('AppRoot bill reminders (spec §6, D126)', () {
    final RecurringRule waitingToday = WorkedExample.electricity.copyWith(
      amountMode: AmountMode.varies,
      schedule: const Schedule(frequency: Frequency.monthly, anchor: WorkedExample.today),
      nextDue: WorkedExample.today,
    );
    FakeServices withWaitingBill() => FakeServices(rules: <RecurringRule>[WorkedExample.salary, WorkedExample.rent, waitingToday])
      ..preferences.reminders = const Option<bool>.of(true);
    const BillReminderTap tapToday = BillReminderTap(ruleId: 3, date: WorkedExample.today);

    testWidgets('a returning user who said Remind me has the next reminder armed', (WidgetTester tester) async {
      await boot(tester, withWaitingBill());
      expect(services.reminders.scheduled.single.date, const CalendarDate(2026, 11, 26));
      expect(services.reminders.kept, <int>{BillReminder.idFor(3, WorkedExample.today)});
    });

    testWidgets('a reminder that started the app opens the bill\'s amount sheet over Home', (WidgetTester tester) async {
      final FakeServices fakes = withWaitingBill()..reminders.launchedBy = const Option<BillReminderTap>.of(tapToday);
      await boot(tester, fakes);
      expect(find.byType(BillAmountSheet), findsOneWidget);
      expect(find.text('Electricity · 26 Oct'), findsOneWidget);
    });

    testWidgets('a tap while in Settings goes back to Home, then opens the sheet', (WidgetTester tester) async {
      await boot(tester, withWaitingBill());
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await settle(tester);
      expect(find.byType(SettingsPage), findsOneWidget);
      services.reminders.tapOn(tapToday);
      await settle(tester);
      expect(find.byType(SettingsPage), findsNothing);
      expect(find.byType(BillAmountSheet), findsOneWidget);
    });

    testWidgets('a tap for a bill already answered shows only Home', (WidgetTester tester) async {
      await boot(tester, withWaitingBill());
      services.reminders.tapOn(const BillReminderTap(ruleId: 3, date: CalendarDate(2026, 9, 26)));
      await settle(tester);
      expect(find.byType(BillAmountSheet), findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('switching a bill to Changes every month asks once; Remind me asks Android', (WidgetTester tester) async {
      await boot(tester, FakeServices());
      await tester.tap(find.byType(DueSoonRow));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-row-mode')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-mode-varies')));
      await settle(tester);
      Navigator.of(tester.element(find.byType(BillSheet))).pop();
      await settle(tester);
      expect(find.text("Remind you on the day it's due?"), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('remind-yes')));
      await settle(tester);
      expect(services.preferences.reminders, const Option<bool>.of(true));
      expect(services.reminders.permissionAsks, 1);
      expect(services.reminders.scheduled.single.billName, 'Electricity');
      expect(find.byType(RemindRefusedSheet), findsNothing);
    });

    testWidgets('Remind me with the permission refused says reminders are off (E-i)', (WidgetTester tester) async {
      final FakeServices fakes = FakeServices()..reminders.granted = false;
      await boot(tester, fakes);
      await tester.tap(find.byType(DueSoonRow));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-row-mode')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-mode-varies')));
      await settle(tester);
      Navigator.of(tester.element(find.byType(BillSheet))).pop();
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('remind-yes')));
      await settle(tester);
      expect(find.text('Reminders are off. Home still shows bills that need an amount.'), findsOneWidget);
    });

    testWidgets('a bill switched with the question already answered asks nothing', (WidgetTester tester) async {
      await boot(tester, FakeServices()..preferences.reminders = const Option<bool>.of(false));
      await tester.tap(find.byType(DueSoonRow));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-row-mode')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-mode-varies')));
      await settle(tester);
      Navigator.of(tester.element(find.byType(BillSheet))).pop();
      await settle(tester);
      expect(find.byType(RemindAskSheet), findsNothing);
    });
  });

  group('AppRoot your usual (FR-AD-10, BR-10, BR-17, D153)', () {
    const ValueKey<String> addKey = ValueKey<String>('add-key');
    const ValueKey<String> pillKey = ValueKey<String>('usual-pill');
    final DateTime mondayTen = DateTime(2026, 10, 26, 10, 5);

    /// Mockup 40's chai habit, with Chai as a category of the user's own.
    FakeServices withChaiHabit({DateTime? now, List<Entry> more = const <Entry>[]}) =>
        FakeServices(entries: <Entry>[...chaiWeekdays(today: WorkedExample.today), ...more])
          ..categories.categories.add(chai)
          ..clock.current = now ?? mondayTen;

    Future<void> openAdd(WidgetTester tester) async {
      await tester.tap(find.byKey(addKey));
      await settle(tester);
    }

    Future<void> tapPill(WidgetTester tester) async {
      await tester.tap(find.byKey(pillKey));
      await settle(tester);
    }

    testWidgets('Add shows Chai ₹20 · your usual in the first frame (AC-1, NFR-1)', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester, withChaiHabit());

      await tester.tap(find.byKey(addKey));
      await tester.pump();

      expect(find.byKey(pillKey), findsOneWidget);
      expect(find.bySemanticsLabel('Add Chai, 20 rupees, your usual'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('at 3:30 pm the slot is empty', (WidgetTester tester) async {
      await boot(tester, withChaiHabit(now: DateTime(2026, 10, 26, 15, 30)));
      await openAdd(tester);
      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(find.byKey(pillKey), findsNothing);
    });

    testWidgets('on Saturday the slot is empty', (WidgetTester tester) async {
      await boot(tester, withChaiHabit(now: DateTime(2026, 10, 24, 10, 5)));
      await openAdd(tester);
      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(find.byKey(pillKey), findsNothing);
    });

    testWidgets("with the worked example's entries there is no habit and no pill", (WidgetTester tester) async {
      await boot(tester, FakeServices()..clock.current = mondayTen);
      await openAdd(tester);
      expect(find.byKey(pillKey), findsNothing);
    });

    testWidgets('one tap saves, closes the tray and offers Undo on Home (AC-4, BR-10)', (WidgetTester tester) async {
      await boot(tester, withChaiHabit());
      await openAdd(tester);

      await tapPill(tester);

      expect(find.byType(AddEntryTray), findsNothing);
      expect(
        services.ledger.saved.single,
        EntryDraft(amount: Money.fromMajor(20), kind: EntryKind.spent, categoryId: chai.id, date: WorkedExample.today),
      );
      expect(find.text('Added ₹20 to Chai'), findsOneWidget);
      expect(find.descendant(of: find.byType(UsualAddedNotice), matching: find.byType(HomePage)), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('a normal tile save offers no Undo (BR-10)', (WidgetTester tester) async {
      await boot(tester, withChaiHabit());
      await openAdd(tester);
      await tester.tap(find.byKey(const ValueKey<String>('keypad-3')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('add-next')));
      await settle(tester);
      await tester.tap(find.bySemanticsLabel('Food. Save'));
      await settle(tester);

      expect(find.byType(AddEntryTray), findsNothing);
      expect(find.byType(HisaabSnackbarBar), findsNothing);
    });

    testWidgets('closing the tray without saving offers no Undo', (WidgetTester tester) async {
      await boot(tester, withChaiHabit());
      await openAdd(tester);
      await tester.binding.handlePopRoute();
      await settle(tester);

      expect(find.byType(AddEntryTray), findsNothing);
      expect(find.byType(HisaabSnackbarBar), findsNothing);
      expect(services.ledger.saved, isEmpty);
    });

    testWidgets('Undo removes the entry; reopening Add the same day shows no pill (E63)', (WidgetTester tester) async {
      await boot(tester, withChaiHabit());
      await openAdd(tester);
      await tapPill(tester);
      final int withAdd = services.ledger.entries.length;

      await tester.tap(find.text('Undo'));
      await settle(tester);

      expect(services.ledger.entries, hasLength(withAdd - 1));
      expect(services.states.states[chai.id]?.quietOn, const Option<CalendarDate>.of(WorkedExample.today));
      await openAdd(tester);
      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(find.byKey(pillKey), findsNothing);
    });

    testWidgets('after the tap, reopening Add shows no pill: Chai is logged today (E65)', (WidgetTester tester) async {
      await boot(tester, withChaiHabit());
      await openAdd(tester);
      await tapPill(tester);

      await openAdd(tester);

      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(find.byKey(pillKey), findsNothing);
    });

    testWidgets('from the Spends tab the Undo shows over Spends (BR-10)', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester, withChaiHabit());
      await tester.tap(find.descendant(of: find.byType(HisaabDock), matching: find.bySemanticsLabel('Spends')));
      await settle(tester);
      expect(find.byType(HomePage), findsNothing);

      await openAdd(tester);
      await tapPill(tester);

      expect(find.text('Added ₹20 to Chai'), findsOneWidget);
      expect(find.descendant(of: find.byType(UsualAddedNotice), matching: find.byType(SpendsPage)), findsOneWidget);
      handle.dispose();
    });

    testWidgets('opening Add before the habits have loaded shows no pill, then or later (AC-1)', (WidgetTester tester) async {
      final Completer<void> slow = Completer<void>();
      await boot(tester, withChaiHabit()..states.nextReadGate = slow);

      await openAdd(tester);
      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(find.byKey(pillKey), findsNothing);

      slow.complete();
      await settle(tester);
      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(find.byKey(pillKey), findsNothing);
    });

    testWidgets('editing an entry shows no pill (AC-1)', (WidgetTester tester) async {
      final Entry lunch = Entry(
        id: 900,
        amount: Money.fromMajor(120),
        kind: EntryKind.spent,
        categoryId: food.id,
        date: WorkedExample.today,
        createdAt: DateTime(2026, 10, 26, 9),
        note: 'Lunch box',
      );
      await boot(tester, withChaiHabit(more: <Entry>[lunch]));
      await tester.ensureVisible(find.text('Lunch box'));
      await settle(tester);

      await tester.tap(find.text('Lunch box'));
      await settle(tester);

      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(find.byKey(pillKey), findsNothing);
    });

    testWidgets('the habits reload at midnight: a tray on the new day has the pill (BR-8, E66)', (WidgetTester tester) async {
      await boot(tester, withChaiHabit(now: DateTime(2026, 10, 25, 23, 59, 30)));
      services.clock.advance(const Duration(seconds: 31));
      await tester.pump(const Duration(seconds: 31));
      await settle(tester);
      services.clock.current = mondayTen;

      await openAdd(tester);

      expect(find.byKey(pillKey), findsOneWidget);
    });

    testWidgets('the habits reload on resume: a tray after a night away has the pill (BR-8)', (WidgetTester tester) async {
      await boot(tester, withChaiHabit(now: DateTime(2026, 10, 25, 16)));
      services.clock.current = mondayTen;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);

      await openAdd(tester);

      expect(find.byKey(pillKey), findsOneWidget);
    });

    testWidgets('an app left open past midnight with no reload yet offers nothing stale (M18)', (WidgetTester tester) async {
      await boot(tester, withChaiHabit());
      await openAdd(tester);
      expect(find.byKey(pillKey), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      // why: the clock jumps with no midnight tick and no resume, so the index is still Monday's.
      services.clock.current = DateTime(2026, 10, 27, 10, 5);

      await openAdd(tester);

      expect(find.byKey(pillKey), findsNothing);
    });

    testWidgets('Settings › Categories › Chai shows the row; Forget, back, Add: no pill (AC-6, BR-17)', (WidgetTester tester) async {
      await boot(tester, withChaiHabit());
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await settle(tester);
      await tester.ensureVisible(find.byKey(const ValueKey<String>('open-categories')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('open-categories')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('category-own_13')));
      await settle(tester);
      expect(find.text('Your usual'), findsOneWidget);
      expect(find.text('₹20, weekdays around 10 am'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('usual-forget')));
      await settle(tester);
      expect(find.text('Your usual'), findsNothing);
      expect(find.text('Forgotten'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await settle(tester);
      await tester.tap(findTooltip('Back'));
      await settle(tester);
      await tester.tap(findTooltip('Back'));
      await settle(tester);

      await openAdd(tester);
      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(find.byKey(pillKey), findsNothing);
    });
  });
}

Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}
