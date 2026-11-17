import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/add_entry/presentation/bloc/entry_card_bloc.dart';
import 'package:hisaab/add_entry/presentation/bloc/entry_card_event.dart';
import 'package:hisaab/add_entry/presentation/bloc/entry_card_state.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/ledger/ledger.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeHaptics haptics;
  late FakeClock clock;
  late CycleSummary summary;
  late FakeCategoryRepository categories;

  /// Food ₹60, today, "Chai & samosa" (id 4).
  Entry chai() => WorkedExample.entries.firstWhere((Entry e) => e.id == 4);

  setUp(() async {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    haptics = FakeHaptics();
    clock = FakeClock(WorkedExample.now);
    categories = FakeCategoryRepository();
    summary = (await GetCycleSummary(
      ledger: ledger,
      recurring: FakeRecurringRepository(WorkedExample.rules),
      settings: FakeBudgetSettingsRepository(),
      periods: const PeriodCalculator(),
      clock: clock,
    )(const NoParams())
            .run())
        .getOrElse((Failure f) => fail(f.message));
  });

  tearDown(() => ledger.dispose());

  EntryCardBloc build() {
    final EntryCardBloc bloc = EntryCardBloc(
      saveEntry: SaveEntry(ledger: ledger, recurring: FakeRecurringRepository(WorkedExample.rules), clock: clock),
      addOwnCategory: AddOwnCategory(categories: categories),
      haptics: haptics,
      clock: clock,
    );
    addTearDown(bloc.close);
    return bloc;
  }

  Future<EntryCardBloc> opened({Entry? entry, Option<CardPart> part = const Option<CardPart>.none(), List<Category> all = seedCategories}) async {
    final EntryCardBloc bloc = build();
    await bloc.dispatch(EntryCardOpened(entry ?? chai(), categories: all, summary: Option<CycleSummary>.of(summary), part: part));
    return bloc;
  }

  EntryCardForm form(EntryCardBloc bloc) => (bloc.state as EntryCardOpen).form;

  Future<void> type(EntryCardBloc bloc, String keys) async {
    for (final String key in keys.split('')) {
      await bloc.dispatch(EntryCardKeyPressed(key));
    }
  }

  Future<Entry> stored(int id) async => (await ledger.entriesBetween(const CalendarDate(2026, 9, 1), WorkedExample.today).run())
      .getOrElse((Failure f) => fail(f.message))
      .firstWhere((Entry e) => e.id == id);

  group('EntryCardBloc opening (FR-AD-8 AC-1, AC-2)', () {
    test('starts closed', () => expect(build().state, const EntryCardClosed()));

    test('opens on the entry as it is, nothing unfolded, nothing changed', () async {
      final EntryCardForm card = form(await opened());
      expect((card.rupees, card.categoryId, card.date, card.note), (60, SeedCategoryIds.food, WorkedExample.today, 'Chai & samosa'));
      expect(card.part, const Option<CardPart>.none());
      expect(card.changes, isEmpty);
      expect(card.earliestDate, summary.earliestEntryDate);
      expect(haptics.events, <String>['tick']);
    });

    test('opens with a part unfolded when the tap asked for one', () async {
      expect(form(await opened(part: const Option<CardPart>.of(CardPart.amount))).part, const Option<CardPart>.of(CardPart.amount));
    });

    test('a part tap unfolds it, a second tap folds it, another part replaces it', () async {
      final EntryCardBloc bloc = await opened();
      await bloc.dispatch(const EntryCardPartTapped(CardPart.category));
      expect(form(bloc).part, const Option<CardPart>.of(CardPart.category));
      await bloc.dispatch(const EntryCardPartTapped(CardPart.day));
      expect(form(bloc).part, const Option<CardPart>.of(CardPart.day));
      await bloc.dispatch(const EntryCardPartTapped(CardPart.day));
      expect(form(bloc).part, const Option<CardPart>.none());
    });

    test('tiles are the kind\'s shown categories, plus a hidden own one only while it holds the entry', () async {
      const Category gym = Category(id: 30, key: 'own_30', iconKey: 'gym', kind: EntryKind.spent, sort: 8, customName: 'Gym', hidden: true);
      const Category pets = Category(id: 31, key: 'own_31', iconKey: 'pets', kind: EntryKind.spent, sort: 9, customName: 'Pets', hidden: true);
      final Entry inGym = Entry(id: 4, amount: Money.fromMajor(60), kind: EntryKind.spent, categoryId: 30, date: WorkedExample.today, createdAt: WorkedExample.now);
      final EntryCardForm card = form(await opened(entry: inGym, all: <Category>[...seedCategories, gym, pets]));
      expect(card.tiles.map((Category c) => c.id), <int>[1, 2, 3, 4, 5, 6, 7, 8, 30]);
    });
  });

  group('EntryCardBloc amount (AC-3)', () {
    test('the first digit replaces the old amount; later digits append', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.amount));
      await type(bloc, '3');
      expect(form(bloc).shownRupees, 3);
      await type(bloc, '50');
      expect(form(bloc).shownRupees, 350);
      expect(form(bloc).rupees, 60, reason: 'not kept until the part folds');
    });

    test('⌫ first removes one digit of the old amount', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.amount));
      await bloc.dispatch(const EntryCardBackspacePressed());
      expect(form(bloc).shownRupees, 6);
    });

    test('00 first replaces with ₹0, which the keep key refuses', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.amount));
      await type(bloc, '0');
      await bloc.dispatch(const EntryCardAmountKept());
      expect((form(bloc).rupees, form(bloc).part), (60, const Option<CardPart>.of(CardPart.amount)));
    });

    test('keep stores the typed amount and folds the keypad', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.amount));
      await type(bloc, '350');
      await bloc.dispatch(const EntryCardAmountKept());
      expect((form(bloc).rupees, form(bloc).typed, form(bloc).part), (350, const Option<int>.none(), const Option<CardPart>.none()));
      expect(form(bloc).changes, <CardChange>[CardChange.amount]);
    });

    test('a 10th digit is refused with the reject haptic', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.amount));
      await type(bloc, '9999999999');
      expect(form(bloc).shownRupees, 999999999);
      expect((bloc.state as EntryCardOpen).rejections, 1);
      expect(haptics.events.last, 'reject');
    });

    test('a long press clears to ₹0', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.amount));
      await bloc.dispatch(const EntryCardCleared());
      expect(form(bloc).shownRupees, 0);
    });

    test('moving to another part keeps a typed amount (AC-8)', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.amount));
      await type(bloc, '75');
      await bloc.dispatch(const EntryCardPartTapped(CardPart.day));
      expect((form(bloc).rupees, form(bloc).part), (75, const Option<CardPart>.of(CardPart.day)));
    });
  });

  group('EntryCardBloc category, day and note (AC-4, AC-6, AC-7)', () {
    test('a tile moves the entry and folds the grid', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.category));
      await bloc.dispatch(const EntryCardCategoryPicked(SeedCategoryIds.travel));
      expect((form(bloc).categoryId, form(bloc).part), (SeedCategoryIds.travel, const Option<CardPart>.none()));
    });

    test('a day moves the entry, kept within the allowed days', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.day));
      await bloc.dispatch(EntryCardDayPicked(WorkedExample.today.addDays(-1)));
      expect((form(bloc).date, form(bloc).part), (WorkedExample.today.addDays(-1), const Option<CardPart>.none()));
      await bloc.dispatch(EntryCardDayPicked(WorkedExample.today.addDays(3)));
      expect(form(bloc).date, WorkedExample.today);
      await bloc.dispatch(const EntryCardDayPicked(CalendarDate(2020, 1, 1)));
      expect(form(bloc).date, summary.earliestEntryDate);
    });

    test('the note changes with no other effect', () async {
      final EntryCardBloc bloc = await opened();
      await bloc.dispatch(const EntryCardNoteChanged('Chai, extra plate'));
      expect(form(bloc).changes, <CardChange>[CardChange.note]);
    });
  });

  group('EntryCardBloc new category (AC-5)', () {
    test('New opens naming; Move to makes the category and moves the entry, nothing written yet', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.category));
      await bloc.dispatch(const EntryCardPartTapped(CardPart.naming));
      await bloc.dispatch(const EntryCardNameChanged('Groceries'));
      expect(form(bloc).draftIconKey, CategoryIcon.forName('Groceries'));
      await bloc.dispatch(const EntryCardNewCategorySaved(<int, String>{}));
      final EntryCardForm card = form(bloc);
      final Category made = card.categories.firstWhere((Category c) => c.id == card.categoryId);
      expect((made.customName, card.part, card.draftName), ('Groceries', const Option<CardPart>.none(), ''));
      expect((await stored(4)).categoryId, SeedCategoryIds.food);
    });

    test('a picked icon is used; the name\'s own icon follows the name again', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.naming));
      await bloc.dispatch(const EntryCardNameChanged('Kids'));
      await bloc.dispatch(const EntryCardIconPicked('pets'));
      expect(form(bloc).draftIcon, const Option<String>.of('pets'));
      await bloc.dispatch(EntryCardIconPicked(CategoryIcon.forName('Kids')));
      expect(form(bloc).draftIcon, const Option<String>.none());
    });

    test('a name that matches moves the entry to that category', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.naming));
      await bloc.dispatch(const EntryCardNameChanged('Travel'));
      await bloc.dispatch(const EntryCardNewCategorySaved(<int, String>{SeedCategoryIds.travel: 'Travel'}));
      expect(form(bloc).categoryId, SeedCategoryIds.travel);
    });

    test('an empty name does nothing', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.naming));
      await bloc.dispatch(const EntryCardNewCategorySaved(<int, String>{}));
      expect(form(bloc).part, const Option<CardPart>.of(CardPart.naming));
    });

    test('a refused name stays on naming and says it failed', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.naming));
      await bloc.dispatch(const EntryCardNameChanged('Savings'));
      await bloc.dispatch(const EntryCardNewCategorySaved(<int, String>{}));
      expect(((bloc.state as EntryCardOpen).failed, form(bloc).part), (true, const Option<CardPart>.of(CardPart.naming)));
    });
  });

  group('EntryCardBloc closing (AC-9, AC-10, BR-10)', () {
    test('Done with no change writes nothing and plays no haptic', () async {
      final EntryCardBloc bloc = await opened();
      haptics.events.clear();
      await bloc.dispatch(const EntryCardDone());
      expect(bloc.state, const EntryCardClosed());
      expect(haptics.events, isEmpty);
    });

    test('Done writes once, keeps created_at, and offers the change for Undo', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.amount));
      await type(bloc, '350');
      await bloc.dispatch(const EntryCardPartTapped(CardPart.category));
      await bloc.dispatch(const EntryCardCategoryPicked(SeedCategoryIds.travel));
      await bloc.dispatch(const EntryCardNoteChanged('  Chai  '));
      await bloc.dispatch(const EntryCardDone());
      final Entry saved = await stored(4);
      expect((saved.amount, saved.categoryId, saved.note, saved.createdAt), (Money.fromMajor(350), SeedCategoryIds.travel, 'Chai', chai().createdAt));
      final EntryEdit edit = (bloc.state as EntryCardClosed).edit.getOrElse(() => fail('no edit offered'));
      expect(edit.original, chai());
      expect(edit.changes, <CardChange>[CardChange.amount, CardChange.category, CardChange.note]);
      expect(haptics.events.last, 'success');
    });

    test('Done keeps an amount still being typed', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.amount));
      await type(bloc, '90');
      await bloc.dispatch(const EntryCardDone());
      expect((await stored(4)).amount, Money.fromMajor(90));
    });

    test('a failed write keeps the card open and says so', () async {
      final EntryCardBloc bloc = await opened();
      await bloc.dispatch(const EntryCardNoteChanged('x'));
      await ledger.delete(4).run();
      await bloc.dispatch(const EntryCardDone());
      expect((bloc.state as EntryCardOpen).failed, isTrue);
      expect(haptics.events.last, 'reject');
    });

    test('Undo writes the entry back exactly as it was', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.amount));
      await type(bloc, '350');
      await bloc.dispatch(const EntryCardDone());
      final EntryEdit edit = (bloc.state as EntryCardClosed).edit.getOrElse(() => fail('no edit'));
      await bloc.dispatch(EntryCardUndoRequested(edit));
      expect(await stored(4), chai());
      expect(bloc.state, const EntryCardClosed());
    });

    test('Delete closes without writing and hands the entry over', () async {
      final EntryCardBloc bloc = await opened();
      await bloc.dispatch(const EntryCardNoteChanged('changed'));
      await bloc.dispatch(const EntryCardDeleteRequested());
      expect(bloc.state, EntryCardClosed(deleted: Option<Entry>.of(chai())));
      expect(await stored(4), chai());
    });

    test('opening another entry closes the first, writing its change', () async {
      final EntryCardBloc bloc = await opened();
      await bloc.dispatch(const EntryCardNoteChanged('first'));
      final Entry auto = WorkedExample.entries.firstWhere((Entry e) => e.id == 5);
      await bloc.dispatch(EntryCardOpened(auto, categories: seedCategories, summary: Option<CycleSummary>.of(summary)));
      expect((await stored(4)).note, 'first');
      expect(form(bloc).original, auto);
    });
  });

  group('EntryCardBloc Undo failure', () {
    test('a failed Undo leaves the card closed and the edit as written', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.amount));
      await type(bloc, '350');
      await bloc.dispatch(const EntryCardDone());
      final EntryEdit edit = (bloc.state as EntryCardClosed).edit.getOrElse(() => fail('no edit'));
      ledger.failure = DatabaseFailure('down');
      await bloc.dispatch(EntryCardUndoRequested(edit));
      expect(bloc.state, const EntryCardClosed());
      ledger.failure = null;
      expect((await stored(4)).amount, Money.fromMajor(350));
    });
  });

  group('EntryCard events and states have value equality', () {
    final Entry entry = WorkedExample.entries.firstWhere((Entry e) => e.id == 4);
    final List<(Object, Object, Object)> cases = <(Object, Object, Object)>[
      (EntryCardOpened(entry, categories: seedCategories), EntryCardOpened(entry, categories: seedCategories), EntryCardOpened(entry, categories: const <Category>[])),
      (const EntryCardPartTapped(CardPart.day), const EntryCardPartTapped(CardPart.day), const EntryCardPartTapped(CardPart.amount)),
      (const EntryCardKeyPressed('1'), const EntryCardKeyPressed('1'), const EntryCardKeyPressed('2')),
      (const EntryCardCategoryPicked(1), const EntryCardCategoryPicked(1), const EntryCardCategoryPicked(2)),
      (EntryCardDayPicked(WorkedExample.today), EntryCardDayPicked(WorkedExample.today), EntryCardDayPicked(WorkedExample.today.addDays(-1))),
      (const EntryCardNoteChanged('a'), const EntryCardNoteChanged('a'), const EntryCardNoteChanged('b')),
      (const EntryCardNameChanged('a'), const EntryCardNameChanged('a'), const EntryCardNameChanged('b')),
      (const EntryCardIconPicked('a'), const EntryCardIconPicked('a'), const EntryCardIconPicked('b')),
      (const EntryCardNewCategorySaved(<int, String>{1: 'Food'}), const EntryCardNewCategorySaved(<int, String>{1: 'Food'}), const EntryCardNewCategorySaved(<int, String>{})),
      (const EntryCardBackspacePressed(), const EntryCardBackspacePressed(), const EntryCardCleared()),
      (const EntryCardAmountKept(), const EntryCardAmountKept(), const EntryCardDone()),
      (const EntryCardDeleteRequested(), const EntryCardDeleteRequested(), const EntryCardDone()),
      (const EntryCardClosed(), const EntryCardClosed(), EntryCardClosed(deleted: Option<Entry>.of(entry))),
    ];
    for (final (int index, (Object a, Object b, Object c)) in cases.indexed) {
      test('case $index: equal to its twin, not to a different one', () {
        expect(a, b);
        expect(a, isNot(c));
      });
    }

    test('an edit and the saving state compare by value', () async {
      final EntryCardBloc bloc = await opened();
      final EntryCardForm card = form(bloc);
      EntryEdit edit(CalendarDate day) =>
          EntryEdit(original: entry, saved: entry, changes: const <CardChange>[CardChange.note], categories: seedCategories, today: day);
      expect(edit(WorkedExample.today), edit(WorkedExample.today));
      expect(edit(WorkedExample.today), isNot(edit(WorkedExample.today.addDays(-1))));
      expect(EntryCardSaving(card), EntryCardSaving(card));
      expect(EntryCardUndoRequested(edit(WorkedExample.today)), EntryCardUndoRequested(edit(WorkedExample.today)));
    });
  });

  group('EntryCardBloc write order (sequential)', () {
    test('a second Done while the first write is in flight writes nothing more', () async {
      final EntryCardBloc bloc = await opened();
      await bloc.dispatch(const EntryCardNoteChanged('once'));
      final Completer<void> gate = Completer<void>();
      ledger.nextReplaceGate = gate;
      ledger.saved.clear();
      bloc
        ..add(const EntryCardDone())
        ..add(const EntryCardDone());
      await pumpEventQueue();
      gate.complete();
      await pumpEventQueue();
      expect(ledger.saved, hasLength(1));
    });

    test('a row opened while the last card is writing opens after the write', () async {
      final EntryCardBloc bloc = await opened();
      await bloc.dispatch(const EntryCardNoteChanged('first'));
      final Completer<void> gate = Completer<void>();
      ledger.nextReplaceGate = gate;
      final Entry auto = WorkedExample.entries.firstWhere((Entry e) => e.id == 5);
      bloc
        ..add(const EntryCardDone())
        ..add(EntryCardOpened(auto, categories: seedCategories));
      await pumpEventQueue();
      expect(bloc.state, isA<EntryCardSaving>());
      gate.complete();
      await pumpEventQueue();
      expect(form(bloc).original, auto);
      expect((await stored(4)).note, 'first');
    });
  });

  group('EntryCardBloc preview (AC-11)', () {
    test('a typed amount on today\'s spend previews Home\'s figure', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.amount));
      expect(form(bloc).preview, const Option<Money>.none());
      await type(bloc, '160');
      expect(form(bloc).preview, Option<Money>.of(summary.safeToday - Money.fromMajor(100)));
    });

    test('no preview once the day moves off today', () async {
      final EntryCardBloc bloc = await opened(part: const Option<CardPart>.of(CardPart.amount));
      await type(bloc, '160');
      await bloc.dispatch(EntryCardDayPicked(WorkedExample.today.addDays(-1)));
      expect(form(bloc).preview, const Option<Money>.none());
    });
  });
}
