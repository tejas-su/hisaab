import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/add_entry/add_entry.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/core/widgets/hisaab_snackbar_host.dart';
import 'package:hisaab/core/widgets/keypad.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/ledger/presentation/widgets/category_icon_grid.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

/// A list of today's entries with a scope, the outcomes and, when [board], the board beside it.
class _Host extends StatelessWidget {
  const _Host({required this.bloc, required this.entries, required this.summary, required this.deleted, this.board = false});

  final EntryCardBloc bloc;
  final List<Entry> entries;
  final CycleSummary summary;
  final List<Entry> deleted;
  final bool board;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: HisaabSnackbarHost(
          child: EntryCardOutcomes(
            bloc: bloc,
            onDelete: deleted.add,
            child: EntryCardScope(
              bloc: bloc,
              partsInline: !board,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Expanded(
                    child: Builder(
                      builder: (BuildContext context) => ListView(
                        children: <Widget>[
                          const SizedBox(key: ValueKey<String>('outside'), height: 48, child: Text('outside')),
                          for (final Entry entry in entries)
                            EntryCardSlot(
                              key: ValueKey<int>(entry.id),
                              entryId: entry.id,
                              row: ListTile(
                                key: ValueKey<String>('row-${entry.id}'),
                                title: Text(entry.note ?? ''),
                                onTap: () => EntryCardScope.maybeOf(context)
                                    ?.open(entry, categories: seedCategories, summary: Option<CycleSummary>.of(summary)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  if (board) Expanded(child: EntryBoard(bloc: bloc)),
                ],
              ),
            ),
          ),
        ),
      );
}

void main() {
  late FakeLedgerRepository ledger;
  late FakeHaptics haptics;
  late FakeClock clock;
  late CycleSummary summary;
  late EntryCardBloc bloc;
  late List<Entry> deleted;

  List<Entry> today() => WorkedExample.entries.where((Entry e) => e.date == WorkedExample.today).toList();

  setUp(() async {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    haptics = FakeHaptics();
    clock = FakeClock(WorkedExample.now);
    deleted = <Entry>[];
    summary = (await GetCycleSummary(
      ledger: ledger,
      recurring: FakeRecurringRepository(WorkedExample.rules),
      settings: FakeBudgetSettingsRepository(),
      periods: const PeriodCalculator(),
      clock: clock,
    )(const NoParams())
            .run())
        .getOrElse((Failure f) => fail(f.message));
    bloc = EntryCardBloc(
      saveEntry: SaveEntry(ledger: ledger, recurring: FakeRecurringRepository(WorkedExample.rules), clock: clock),
      addOwnCategory: AddOwnCategory(categories: FakeCategoryRepository()),
      haptics: haptics,
      clock: clock,
    );
  });

  tearDown(() async {
    await bloc.close();
    ledger.dispose();
  });

  Future<void> pump(WidgetTester tester, {bool board = false, Size size = TestWindows.phone, bool reduceMotion = false}) => pumpApp(
        tester,
        _Host(bloc: bloc, entries: today(), summary: summary, deleted: deleted, board: board),
        size: size,
        reduceMotion: reduceMotion,
      );

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.settle();
  }

  Future<void> openChai(WidgetTester tester) => tap(tester, find.byKey(const ValueKey<String>('row-4')));

  Future<Entry> stored(int id) async => (await ledger.entriesBetween(const CalendarDate(2026, 9, 1), WorkedExample.today).run())
      .getOrElse((Failure f) => fail(f.message))
      .firstWhere((Entry e) => e.id == id);

  Finder card() => find.byKey(const ValueKey<String>('entry-card-4'));
  Finder key(String name) => find.byKey(ValueKey<String>(name));
  Finder keypadKey(String label) => find.descendant(of: find.byType(Keypad), matching: find.text(label));

  group('EntryCard in a list (FR-AD-8)', () {
    testWidgets('a row opens as a card where it was, with the hint; the other rows fade (AC-1)', (WidgetTester tester) async {
      await pump(tester);
      await openChai(tester);
      expect(card(), findsOneWidget);
      expect(find.text('₹60'), findsOneWidget);
      expect(find.text('Tap any part to change it'), findsOneWidget);
      final AnimatedOpacity other = tester.widget<AnimatedOpacity>(
        find.ancestor(of: key('row-5'), matching: find.byType(AnimatedOpacity)).first,
      );
      expect(other.opacity, 0.35);
    });

    testWidgets('the amount: first digit replaces, Keep and Change to, then Done offers Undo (AC-3, AC-9)', (WidgetTester tester) async {
      await pump(tester);
      await openChai(tester);
      await tap(tester, key('entry-card-amount'));
      expect(find.text('Keep ₹60'), findsOneWidget);
      await tap(tester, keypadKey('3'));
      await tap(tester, keypadKey('5'));
      await tap(tester, keypadKey('0'));
      expect(find.text('Change to ₹350'), findsOneWidget);
      await tap(tester, key('entry-card-keep'));
      expect(find.byType(Keypad), findsNothing);
      await tap(tester, key('entry-card-done'));
      expect(card(), findsNothing);
      expect(find.text('Changed to ₹350'), findsOneWidget);
      expect((await tester.runAsync(() => stored(4)))!.amount.floorMajor, 350);
      await tap(tester, find.text('Undo'));
      expect((await tester.runAsync(() => stored(4)))!, WorkedExample.entries.firstWhere((Entry e) => e.id == 4));
    });

    testWidgets('⌫ edits, a long press clears, and ₹0 can\'t be kept', (WidgetTester tester) async {
      await pump(tester);
      await openChai(tester);
      await tap(tester, key('entry-card-amount'));
      final Finder backspace = find.bySemanticsLabel('Delete last digit. Touch and hold to clear all');
      await tap(tester, backspace);
      expect(find.text('Change to ₹6'), findsOneWidget);
      await tester.longPress(backspace);
      await tester.settle();
      expect(find.text('Type an amount'), findsOneWidget);
    });

    testWidgets('the category: Food is marked now; Travel moves it (AC-4)', (WidgetTester tester) async {
      final SemanticsHandle semantics = tester.ensureSemantics();
      await pump(tester);
      await openChai(tester);
      await tap(tester, key('entry-card-category'));
      expect(find.bySemanticsLabel('Food, now'), findsOneWidget);
      await tap(tester, key('card-tile-${SeedCategoryIds.travel}'));
      expect(key('card-tile-${SeedCategoryIds.travel}'), findsNothing);
      await tap(tester, key('entry-card-done'));
      expect(find.text('Moved to Travel'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('New names a category in the card and moves the entry there (AC-5)', (WidgetTester tester) async {
      await pump(tester);
      await openChai(tester);
      await tap(tester, key('entry-card-category'));
      await tap(tester, find.text('New'));
      expect(find.text('Type a name'), findsOneWidget);
      await tester.enterText(key('entry-card-name'), 'Groceries');
      await tester.settle();
      expect(find.text('Icon from the name: Groceries'), findsOneWidget);
      await tap(tester, key('entry-card-change-icon'));
      expect(find.byType(CategoryIconGrid), findsOneWidget);
      await tap(tester, key('entry-card-change-icon'));
      await tap(tester, key('entry-card-move'));
      expect(find.text('Groceries'), findsWidgets);
      await tap(tester, key('entry-card-done'));
      expect(find.text('Moved to Groceries'), findsOneWidget);
    });

    testWidgets('a name chip fills the field; a picked icon is named; the done key moves it', (WidgetTester tester) async {
      await pump(tester);
      await openChai(tester);
      await tap(tester, key('entry-card-category'));
      await tap(tester, find.text('New'));
      await tap(tester, find.text('Family'));
      expect(find.text('Move to Family'), findsOneWidget);
      await tap(tester, key('entry-card-change-icon'));
      // why: the icon grid is about 1,000dp tall inside the card; the list scrolls down to Gym.
      await tester.drag(find.text("What's it called?"), const Offset(0, -700));
      await tester.settle();
      await tester.tap(key('icon-gym'));
      await tester.settle();
      expect(find.text('Icon: Gym'), findsOneWidget);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.settle();
      expect(key('entry-card-name'), findsNothing);
      expect(find.text('Family'), findsWidgets);
    });

    testWidgets('a typed name that exists says it moves there; back goes to the grid', (WidgetTester tester) async {
      await pump(tester);
      await openChai(tester);
      await tap(tester, key('entry-card-category'));
      await tap(tester, find.text('New'));
      await tester.enterText(key('entry-card-name'), 'Travel');
      await tester.settle();
      expect(find.text('You have Travel already. It moves there.'), findsOneWidget);
      expect(find.text('Move to Travel'), findsOneWidget);
      await tap(tester, key('entry-card-back-to-grid'));
      expect(key('card-tile-${SeedCategoryIds.food}'), findsOneWidget);
    });

    testWidgets('the day: Yesterday moves it, and the Undo bar says so (AC-6)', (WidgetTester tester) async {
      await pump(tester);
      await openChai(tester);
      await tap(tester, key('entry-card-day'));
      await tap(tester, key('entry-card-day-${WorkedExample.today.addDays(-1).toIso()}'));
      await tap(tester, key('entry-card-done'));
      expect(find.text('Moved to yesterday'), findsOneWidget);
    });

    testWidgets('Earlier opens the date picker within the allowed days', (WidgetTester tester) async {
      await pump(tester);
      await openChai(tester);
      await tap(tester, key('entry-card-day'));
      await tap(tester, key('entry-card-earlier'));
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tap(tester, find.text('20'));
      await tap(tester, find.text('OK'));
      await tap(tester, key('entry-card-done'));
      expect(find.text('Moved to 20 Oct'), findsOneWidget);
    });

    testWidgets('the note is typed in place; removing it says so; two changes are counted (AC-7)', (WidgetTester tester) async {
      await pump(tester);
      await openChai(tester);
      await tester.enterText(key('entry-card-note'), '');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.settle();
      await tap(tester, key('entry-card-done'));
      expect(find.text('Note removed'), findsOneWidget);

      await openChai(tester);
      await tester.enterText(key('entry-card-note'), 'Tea');
      await tap(tester, key('entry-card-day'));
      await tap(tester, key('entry-card-day-${WorkedExample.today.addDays(-1).toIso()}'));
      await tap(tester, key('entry-card-done'));
      expect(find.text('2 changes saved'), findsOneWidget);
    });

    testWidgets('a changed note says Note changed', (WidgetTester tester) async {
      await pump(tester);
      await openChai(tester);
      await tester.enterText(key('entry-card-note'), 'Tea');
      await tap(tester, key('entry-card-done'));
      expect(find.text('Note changed'), findsOneWidget);
    });

    testWidgets('Delete closes the card and hands the entry to the page (AC-10)', (WidgetTester tester) async {
      await pump(tester);
      await openChai(tester);
      await tap(tester, key('entry-card-delete'));
      expect(card(), findsNothing);
      expect(deleted.map((Entry e) => e.id), <int>[4]);
    });

    testWidgets('a tap outside closes it; with no change nothing is offered (AC-9)', (WidgetTester tester) async {
      await pump(tester);
      await openChai(tester);
      await tester.tap(key('outside'));
      await tester.settle();
      expect(card(), findsNothing);
      expect(find.text('Undo'), findsNothing);
    });

    testWidgets('Back closes an open card instead of leaving (AC-9)', (WidgetTester tester) async {
      await pump(tester);
      await openChai(tester);
      await tester.binding.handlePopRoute();
      await tester.settle();
      expect(card(), findsNothing);
    });

    testWidgets('a failed write keeps the card and says so', (WidgetTester tester) async {
      await pump(tester);
      await openChai(tester);
      await tester.enterText(key('entry-card-note'), 'Tea');
      ledger.failure = DatabaseFailure('down');
      await tap(tester, key('entry-card-done'));
      expect(card(), findsOneWidget);
      expect(find.text("Couldn't save. Try again."), findsOneWidget);
    });

    testWidgets('a 10th digit shakes and rings the amount', (WidgetTester tester) async {
      await pump(tester);
      await openChai(tester);
      await tap(tester, key('entry-card-amount'));
      for (int i = 0; i < 10; i++) {
        await tap(tester, keypadKey('9'));
      }
      expect(find.text('₹99,99,99,999'), findsOneWidget);
      expect(haptics.events.last, 'reject');
    });

    testWidgets('with reduced motion it still opens and closes', (WidgetTester tester) async {
      await pump(tester, reduceMotion: true);
      await openChai(tester);
      expect(card(), findsOneWidget);
      await tap(tester, key('entry-card-done'));
      expect(card(), findsNothing);
    });
  });

  group('EntryBoard (AC-12)', () {
    testWidgets('shows every part at once beside the card, with a live preview', (WidgetTester tester) async {
      await pump(tester, board: true, size: TestWindows.tablet);
      expect(find.text('Change anything'), findsNothing);
      await openChai(tester);
      expect(find.text('Change anything'), findsOneWidget);
      expect(find.text("Updates when you're done"), findsOneWidget);
      expect(find.byType(Keypad), findsOneWidget);
      expect(key('card-tile-${SeedCategoryIds.travel}'), findsOneWidget);
      await tap(tester, keypadKey('1'));
      await tap(tester, keypadKey('6'));
      await tap(tester, keypadKey('0'));
      expect(find.textContaining("Today's share"), findsOneWidget);
      await tap(tester, key('entry-card-amount'));
      await tap(tester, find.text('New'));
      expect(key('entry-card-name'), findsOneWidget);
      await tap(tester, key('entry-card-done'));
      expect(find.text('Changed to ₹160'), findsOneWidget);
    });

    testWidgets('a pick on the board does not count as a tap outside', (WidgetTester tester) async {
      await pump(tester, board: true, size: TestWindows.tablet);
      await openChai(tester);
      await tap(tester, key('card-tile-${SeedCategoryIds.travel}'));
      expect(card(), findsOneWidget);
    });
  });
}
