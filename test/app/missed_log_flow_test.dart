import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Option;
import 'package:get_it/get_it.dart';
import 'package:hisaab/add_entry/add_entry.dart';
import 'package:hisaab/app/hisaab_app.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/home/presentation/widgets/due_soon_row.dart';
import 'package:hisaab/home/presentation/widgets/missed_log_row.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_services.dart';
import '../helpers/fixtures/habits/chai_habit.dart';
import '../helpers/fixtures/ledger/categories.dart';
import '../helpers/fixtures/ledger/worked_example.dart';
import '../helpers/pump_app.dart';

/// Mon 26 Oct 2026: Chai's window is 9:45 to 10:45, so the line first shows at 12:15.
DateTime _at(int hour, int minute) => DateTime(2026, 10, 26, hour, minute);

const ValueKey<String> _pill = ValueKey<String>('usual-pill');

/// This cycle's pay, so Home is not in an over state.
final Entry _pay = entryAt(900, seedCategories.firstWhere((Category c) => c.id == SeedCategoryIds.salary), 45000, DateTime(2026, 10, 4, 9), kind: EntryKind.got);

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  late FakeServices services;

  tearDown(() => services.dispose());

  /// The chai habit with no bills, so no bill line holds the nudge slot.
  FakeServices chaiServices({DateTime? now, List<RecurringRule>? rules, bool paid = true}) =>
      FakeServices(entries: <Entry>[...chaiWeekdays(today: WorkedExample.today), if (paid) _pay], rules: rules ?? <RecurringRule>[WorkedExample.salary])
        ..categories.categories.add(chai)
        ..clock.current = now ?? _at(13, 0);

  Future<void> boot(WidgetTester tester, FakeServices fakes, {Size size = TestWindows.phone}) async {
    services = fakes;
    await tester.runAsync(loadAppFonts);
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(HisaabApp(getIt: fakes.register(GetIt.asNewInstance())));
    await _settle(tester);
  }

  Future<void> resume(WidgetTester tester) async {
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _settle(tester);
  }

  Option<CalendarDate> askedOn() => services.states.states[chai.id]?.askedOn ?? const Option<CalendarDate>.none();

  List<String> askedWrites() => services.states.calls.where((String call) => call.startsWith('asked')).toList();

  group('the missed-log line, end to end (FR-HO-3, BR-17, D170)', () {
    testWidgets('a cold start after the window shows the line in Home, and writes asked_on (AC-1, AC-4)', (WidgetTester tester) async {
      await boot(tester, chaiServices());

      expect(find.byType(MissedLogRow), findsOneWidget);
      expect(find.text('Spent on Chai today?'), findsOneWidget);
      expect(find.text('Usually around 10 am.'), findsOneWidget);
      expect(askedOn(), const Option<CalendarDate>.of(WorkedExample.today));
      expect(find.byType(DueSoonRow), findsNothing);
    });

    for (final (int, int, bool) edge in <(int, int, bool)>[(12, 14, false), (12, 15, true)]) {
      testWidgets('at ${edge.$1}:${edge.$2} the line is ${edge.$3 ? 'shown' : 'not shown'} (L6, 90 minutes after the window)', (WidgetTester tester) async {
        await boot(tester, chaiServices(now: _at(edge.$1, edge.$2)));

        expect(find.byType(MissedLogRow), edge.$3 ? findsOneWidget : findsNothing);
      });
    }

    testWidgets('inside the window there is no line: the pill covers it (E103)', (WidgetTester tester) async {
      await boot(tester, chaiServices(now: _at(10, 5)));

      expect(find.byType(MissedLogRow), findsNothing);
      expect(askedWrites(), isEmpty);
    });

    testWidgets('a bill line holds the slot: the missed-log line is not shown and not asked (B4)', (WidgetTester tester) async {
      await boot(tester, chaiServices(rules: WorkedExample.rules));

      expect(find.byType(DueSoonRow), findsOneWidget);
      expect(find.byType(MissedLogRow), findsNothing);
      expect(askedWrites(), isEmpty);
    });

    testWidgets('in an over state the line waits and is not asked (E107)', (WidgetTester tester) async {
      await boot(tester, chaiServices(paid: false));

      expect(find.byType(MissedLogRow), findsNothing);
      expect(askedWrites(), isEmpty);
    });

    testWidgets('a ledger tick or the clock passing the mark adds nothing; the next resume does (D170)', (WidgetTester tester) async {
      await boot(tester, chaiServices(now: _at(11, 0)));
      expect(find.byType(MissedLogRow), findsNothing);

      services.clock.current = _at(13, 0);
      await tester.runAsync(() => services.ledger.add(EntryDraft(amount: Money.fromMajor(40), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today)).run());
      await _settle(tester);
      expect(find.byType(MissedLogRow), findsNothing);

      await resume(tester);

      expect(find.byType(MissedLogRow), findsOneWidget);
    });

    testWidgets('habits that load after Home leave no line that open, and none later (E106)', (WidgetTester tester) async {
      final FakeServices fakes = chaiServices();
      final Completer<void> gate = Completer<void>();
      fakes.states.nextReadGate = gate;
      await boot(tester, fakes);
      expect(find.byType(MissedLogRow), findsNothing);

      gate.complete();
      await _settle(tester);

      expect(find.byType(MissedLogRow), findsNothing);
      expect(askedWrites(), isEmpty);
    });

    testWidgets('a resume after it was asked does not show it again: one question a day (L3)', (WidgetTester tester) async {
      await boot(tester, chaiServices());
      expect(find.byType(MissedLogRow), findsOneWidget);

      await resume(tester);

      expect(find.byType(MissedLogRow), findsNothing);
      expect(askedWrites(), hasLength(1));
    });

    testWidgets('two panes: the line is in Home\'s pane and is asked', (WidgetTester tester) async {
      await boot(tester, chaiServices(), size: TestWindows.tablet);

      expect(find.byType(MissedLogRow), findsOneWidget);
      expect(askedOn(), const Option<CalendarDate>.of(WorkedExample.today));
    });

    testWidgets('an entry in its category by any door removes it', (WidgetTester tester) async {
      await boot(tester, chaiServices());

      await tester.runAsync(() => services.ledger.add(EntryDraft(amount: Money.fromMajor(20), kind: EntryKind.spent, categoryId: chai.id, date: WorkedExample.today)).run());
      await _settle(tester);

      expect(find.byType(MissedLogRow), findsNothing);
    });

    testWidgets('a bill line arriving at a later reload outranks it, and does not hand the slot back when it clears (E108)', (WidgetTester tester) async {
      final FakeServices fakes = chaiServices();
      fakes.recurring.stopped.add(WorkedExample.electricity);
      await boot(tester, fakes);
      expect(find.byType(MissedLogRow), findsOneWidget);

      await tester.runAsync(() => services.recurring.setActive(WorkedExample.electricity.id, active: true).run());
      await _settle(tester);
      expect(find.byType(DueSoonRow), findsOneWidget);
      expect(find.byType(MissedLogRow), findsNothing);

      await tester.runAsync(() => services.recurring.setActive(WorkedExample.electricity.id, active: false).run());
      await _settle(tester);

      expect(find.byType(DueSoonRow), findsNothing);
      expect(find.byType(MissedLogRow), findsNothing);
    });

    testWidgets('midnight removes it', (WidgetTester tester) async {
      await boot(tester, chaiServices());

      await tester.pump(const Duration(hours: 12));
      await _settle(tester);

      expect(find.byType(MissedLogRow), findsNothing);
    });

    testWidgets('forgetting the category removes it', (WidgetTester tester) async {
      await boot(tester, chaiServices());

      await tester.runAsync(() => services.states.put(SuggestionState(categoryId: chai.id, restUntil: Option<CalendarDate>.of(WorkedExample.today.addDays(30)))).run());
      tester.element(find.byType(MissedLogRow)).read<HabitsBloc>().add(const HabitsLoadRequested());
      await _settle(tester);

      expect(find.byType(MissedLogRow), findsNothing);
    });
  });

  group('the tap (FR-HO-3 AC-2, AC-3; FR-AD-10 AC-1)', () {
    testWidgets('opens the tray at step 1 with the pill outside its window, no category chosen, one tick', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester, chaiServices());

      await tester.tap(find.byType(MissedLogRow));
      await _settle(tester);

      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(find.byKey(_pill), findsOneWidget);
      expect(find.bySemanticsLabel('Add Chai, 20 rupees, your usual'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('add-next')), findsOneWidget);
      expect(services.haptics.events.where((String event) => event == 'tick'), hasLength(1));
      expect(find.byType(MissedLogRow), findsOneWidget);
      handle.dispose();
    });

    testWidgets('an Add tray from the dock, outside the window, still shows no pill (regression)', (WidgetTester tester) async {
      await boot(tester, chaiServices());

      await tester.tap(find.byKey(const ValueKey<String>('add-key')));
      await _settle(tester);

      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(find.byKey(_pill), findsNothing);
    });

    testWidgets('Back without saving removes the line, with no haptic and nothing written but asked_on (AC-3, E104)', (WidgetTester tester) async {
      await boot(tester, chaiServices());
      await tester.tap(find.byType(MissedLogRow));
      await _settle(tester);
      final List<String> before = List<String>.of(services.haptics.events);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(find.byType(AddEntryTray), findsNothing);
      expect(find.byType(MissedLogRow), findsNothing);
      expect(services.haptics.events, before);
      expect(services.ledger.saved, isEmpty);
      expect(services.states.states[chai.id], SuggestionState(categoryId: chai.id, askedOn: const Option<CalendarDate>.of(WorkedExample.today)));
      expect(services.states.calls.where((String call) => call.startsWith('put')), isEmpty);
    });

    testWidgets('when the line that opened the tray goes, focus lands on the "Today" heading, not the page top (FR-HO-3 Focus)', (WidgetTester tester) async {
      await boot(tester, chaiServices());
      await tester.tap(find.byType(MissedLogRow));
      await _settle(tester);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Today heading');
    });

    testWidgets('the pill saves the habit\'s amount; the line goes; Undo quiets the category and the line stays gone', (WidgetTester tester) async {
      await boot(tester, chaiServices());
      await tester.tap(find.byType(MissedLogRow));
      await _settle(tester);

      await tester.tap(find.byKey(_pill));
      await _settle(tester);

      expect(services.ledger.saved.single.amount, Money.fromMajor(20));
      expect(services.ledger.saved.single.categoryId, chai.id);
      expect(find.byType(AddEntryTray), findsNothing);
      expect(find.byType(MissedLogRow), findsNothing);

      await tester.tap(find.text('Undo'));
      await _settle(tester);

      expect(find.byType(MissedLogRow), findsNothing);
      expect(services.states.states[chai.id]!.quietOn, const Option<CalendarDate>.of(WorkedExample.today));
    });

    testWidgets('a save through the keypad removes the line', (WidgetTester tester) async {
      await boot(tester, chaiServices());
      await tester.tap(find.byType(MissedLogRow));
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey<String>('keypad-3')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('add-next')));
      await _settle(tester);
      await tester.tap(find.bySemanticsLabel('Chai. Save'));
      await _settle(tester);

      expect(find.byType(MissedLogRow), findsNothing);
      expect(services.ledger.saved.single.categoryId, chai.id);
    });

    testWidgets('an entry deleted later today does not bring it back and asks nothing more (E104)', (WidgetTester tester) async {
      await boot(tester, chaiServices());
      await tester.tap(find.byType(MissedLogRow));
      await _settle(tester);
      await tester.tap(find.byKey(_pill));
      await _settle(tester);
      final int writes = askedWrites().length;

      await tester.runAsync(() => services.ledger.delete(services.ledger.entries.last.id).run());
      await resume(tester);

      expect(find.byType(MissedLogRow), findsNothing);
      expect(askedWrites(), hasLength(writes));
    });
  });
}
