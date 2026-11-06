import 'dart:async';

import 'package:expense_tracker/add_entry/presentation/bloc/add_entry_bloc.dart';
import 'package:expense_tracker/add_entry/presentation/bloc/add_entry_event.dart';
import 'package:expense_tracker/add_entry/presentation/bloc/add_entry_state.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:expense_tracker/core/usecases/use_case.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

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
  late FakeCategoryRepository categoryRepository;

  setUp(() async {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    haptics = FakeHaptics();
    clock = FakeClock(WorkedExample.now);
    categoryRepository = FakeCategoryRepository();
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

  AddEntryBloc build({
    Option<Entry> editing = const Option<Entry>.none(),
    EntryKind kind = EntryKind.spent,
    bool withSummary = true,
    List<Category> categories = seedCategories,
  }) {
    final AddEntryBloc bloc = AddEntryBloc(
      saveEntry: SaveEntry(ledger: ledger, recurring: FakeRecurringRepository(WorkedExample.rules), clock: clock),
      deleteEntry: DeleteEntry(ledger: ledger),
      addOwnCategory: AddOwnCategory(categories: categoryRepository),
      haptics: haptics,
      clock: clock,
      categories: categories,
      summary: withSummary ? Option<CycleSummary>.of(summary) : const Option<CycleSummary>.none(),
      editing: editing,
      kind: kind,
    );
    addTearDown(bloc.close);
    return bloc;
  }

  Future<void> type(AddEntryBloc bloc, String digits) async {
    for (final String key in digits.split('')) {
      await bloc.dispatch(AddEntryKeyPressed(key));
    }
  }

  group('AddEntryBloc step 1: amount (FR-AD-1 to FR-AD-4)', () {
    test('opens on Spent with the 8 Spent tiles, today, and no amount', () {
      final EntryForm form = build().state.form;
      expect((form.kind, form.rupees, form.date, form.step), (EntryKind.spent, 0, WorkedExample.today, AddEntryStep.amount));
      expect(form.tiles.map((Category c) => c.key), <String>['food', 'travel', 'shopping', 'bills', 'fun', 'health', 'home', 'other']);
      expect(form.earliestDate, const CalendarDate(2026, 9, 4));
    });

    test('typing shows live digits with one tick each', () async {
      final AddEntryBloc bloc = build();
      await type(bloc, '2450');
      expect(bloc.state.form.rupees, 2450);
      expect(haptics.events, List<String>.filled(4, 'tick'));
    });

    test('keys typed faster than the bloc handles them keep their order', () async {
      final AddEntryBloc bloc = build()
        ..add(const AddEntryKeyPressed('2'))
        ..add(const AddEntryKeyPressed('4'))
        ..add(const AddEntryKeyPressed('5'));
      await pumpEventQueue();
      expect(bloc.state.form.rupees, 245);
    });

    test('a 10th digit is rejected with a shake and the reject haptic', () async {
      final AddEntryBloc bloc = build();
      await type(bloc, '9999999999');
      expect(bloc.state.form.rupees, 999999999);
      expect((bloc.state as AddEntryEditing).rejections, 1);
      expect(haptics.events.last, 'reject');
    });

    test('quick chips add to the amount (+₹10 then +₹50)', () async {
      final AddEntryBloc bloc = build();
      await bloc.dispatch(const AddEntryQuickAdded(10));
      await bloc.dispatch(const AddEntryQuickAdded(50));
      expect(bloc.state.form.rupees, 60);
    });

    test('a quick chip past the cap is rejected', () async {
      final AddEntryBloc bloc = build();
      await type(bloc, '999999999');
      await bloc.dispatch(const AddEntryQuickAdded(10));
      expect((bloc.state as AddEntryEditing).rejections, 1);
    });

    test('backspace and long-press clear', () async {
      final AddEntryBloc bloc = build();
      await type(bloc, '245');
      await bloc.dispatch(const AddEntryBackspacePressed());
      expect(bloc.state.form.rupees, 24);
      await bloc.dispatch(const AddEntryCleared());
      expect(bloc.state.form.rupees, 0);
    });

    test('the preview shows what is left today (FR-AD-3)', () async {
      final AddEntryBloc bloc = build();
      await type(bloc, '1000');
      expect(bloc.state.form.preview, Option<SpendPreview>.of(FitsToday(Money.fromMajor(430))));
    });

    test('the preview shows the overspend and tomorrow\'s share', () async {
      final AddEntryBloc bloc = build();
      await type(bloc, '2450');
      expect(
        bloc.state.form.preview,
        Option<SpendPreview>.of(OverTodayShare(over: Money.fromMajor(1020), tomorrow: Option<Money>.of(Money.fromMajor(1722)))),
      );
    });

    test('no preview for Got, at ₹0, or without a summary', () async {
      final AddEntryBloc got = build(kind: EntryKind.got);
      await type(got, '500');
      expect(got.state.form.preview, const Option<SpendPreview>.none());
      expect(build().state.form.preview, const Option<SpendPreview>.none());
      final AddEntryBloc noSummary = build(withSummary: false);
      await type(noSummary, '5');
      expect(noSummary.state.form.preview, const Option<SpendPreview>.none());
      expect(noSummary.state.form.earliestDate, WorkedExample.today.addDays(-AddEntryBloc.fallbackHistoryDays));
    });

    test('switching to Got shows the Got tiles and drops the preview', () async {
      final AddEntryBloc bloc = build();
      await type(bloc, '500');
      await bloc.dispatch(const AddEntryKindChanged(EntryKind.got));
      expect(bloc.state.form.tiles.map((Category c) => c.key), <String>['salary', 'other_income']);
      expect(bloc.state.form.preview, const Option<SpendPreview>.none());
      expect(bloc.state.form.rupees, 500);
    });

    test('Next needs an amount, then opens step 2 (FR-AD-4)', () async {
      final AddEntryBloc bloc = build();
      await bloc.dispatch(const AddEntryNextPressed());
      expect(bloc.state.form.step, AddEntryStep.amount);
      await bloc.dispatch(const AddEntryKeyPressed('5'));
      await bloc.dispatch(const AddEntryNextPressed());
      expect(bloc.state.form.step, AddEntryStep.category);
    });

    test('Back from step 2 keeps the amount; back on step 1 changes nothing (FR-AD-7)', () async {
      final AddEntryBloc bloc = build();
      await bloc.dispatch(const AddEntryKeyPressed('5'));
      await bloc.dispatch(const AddEntryNextPressed());
      await bloc.dispatch(const AddEntryBackPressed());
      expect((bloc.state.form.step, bloc.state.form.rupees), (AddEntryStep.amount, 5));
      final AddEntryState onStepOne = bloc.state;
      await bloc.dispatch(const AddEntryBackPressed());
      expect(bloc.state, onStepOne);
    });
  });

  group('AddEntryBloc step 2: save (FR-AD-5, FR-AD-6)', () {
    Future<AddEntryBloc> onStepTwo(String digits) async {
      final AddEntryBloc bloc = build();
      await type(bloc, digits);
      await bloc.dispatch(const AddEntryNextPressed());
      return bloc;
    }

    test('tapping a tile saves, flashes that tile, then finishes with the success haptic', () async {
      final AddEntryBloc bloc = await onStepTwo('60');
      await bloc.dispatch(const AddEntryNoteChanged('  Chai  '));
      final Future<void> expectation = expectLater(
        bloc.stream,
        emitsInOrder(<Matcher>[
          isA<AddEntrySaving>().having((AddEntrySaving s) => s.categoryId, 'categoryId', SeedCategoryIds.food),
          isA<AddEntryFinished>(),
        ]),
      );
      await bloc.dispatch(const AddEntryCategoryPicked(SeedCategoryIds.food));
      await expectation;
      expect(ledger.saved.single, EntryDraft(amount: Money.fromMajor(60), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today, note: 'Chai'));
      expect(haptics.events.last, 'success');
    });

    test('a second tap while saving is ignored', () async {
      final AddEntryBloc bloc = await onStepTwo('6');
      bloc
        ..add(const AddEntryCategoryPicked(SeedCategoryIds.food))
        ..add(const AddEntryCategoryPicked(SeedCategoryIds.travel));
      await pumpEventQueue();
      expect(ledger.saved, hasLength(1));
    });

    test('a failed save keeps everything and says so', () async {
      ledger.failure = DatabaseFailure('disk full');
      final AddEntryBloc bloc = await onStepTwo('6');
      await bloc.dispatch(const AddEntryCategoryPicked(SeedCategoryIds.food));
      expect(bloc.state, isA<AddEntryEditing>().having((AddEntryEditing s) => s.failed, 'failed', isTrue));
      expect(bloc.state.form.rupees, 6);
      expect(haptics.events.last, 'reject');
    });

    test('the date can be yesterday but never before the earliest date or after today', () async {
      final AddEntryBloc bloc = build();
      await bloc.dispatch(AddEntryDateChanged(WorkedExample.today.addDays(-1)));
      expect(bloc.state.form.date, WorkedExample.today.addDays(-1));
      await bloc.dispatch(const AddEntryDateChanged(CalendarDate(2020, 1, 1)));
      expect(bloc.state.form.date, const CalendarDate(2026, 9, 4));
      await bloc.dispatch(AddEntryDateChanged(WorkedExample.today.addDays(3)));
      expect(bloc.state.form.date, WorkedExample.today);
    });

    test('a back-dated entry has no today preview', () async {
      final AddEntryBloc bloc = build();
      await bloc.dispatch(const AddEntryKeyPressed('6'));
      await bloc.dispatch(AddEntryDateChanged(WorkedExample.today.addDays(-1)));
      expect(bloc.state.form.preview, const Option<SpendPreview>.none());
    });

    test('keys and edits are ignored while saving', () async {
      final AddEntryBloc bloc = await onStepTwo('6');
      bloc
        ..add(const AddEntryCategoryPicked(SeedCategoryIds.food))
        ..add(const AddEntryKeyPressed('1'))
        ..add(const AddEntryNoteChanged('late'));
      await pumpEventQueue();
      expect(bloc.state.form.rupees, 6);
      expect(bloc.state.form.note, '');
    });

    test('closing mid-delete does not throw', () async {
      final AddEntryBloc bloc = build(editing: Option<Entry>.of(WorkedExample.entries[3]))..add(const AddEntryDeleteRequested());
      await expectLater(bloc.close(), completes);
    });

    test('closing mid-save does not throw', () async {
      final AddEntryBloc bloc = await onStepTwo('6');
      bloc.add(const AddEntryCategoryPicked(SeedCategoryIds.food));
      await expectLater(bloc.close(), completes);
    });
  });

  group('AddEntryBloc edit mode (FR-AD-8)', () {
    final Entry chai = WorkedExample.entries[3];

    test('opens on step 1 prefilled with the entry', () {
      final EntryForm form = build(editing: Option<Entry>.of(chai)).state.form;
      expect((form.rupees, form.kind, form.note, form.date), (60, EntryKind.spent, 'Chai & samosa', chai.date));
    });

    test('previews only the change in amount', () async {
      final AddEntryBloc bloc = build(editing: Option<Entry>.of(chai));
      await bloc.dispatch(const AddEntryCleared());
      await type(bloc, '160');
      expect(bloc.state.form.preview, Option<SpendPreview>.of(FitsToday(Money.fromMajor(1330))));
    });

    test('editing a bill posted today shows no today preview, since it sits in the pool (D119)', () async {
      final Entry rentToday = Entry(
        id: 50,
        amount: Money.fromMajor(15000),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.home,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
        recurringId: WorkedExample.rent.id,
      );
      final AddEntryBloc bloc = build(editing: Option<Entry>.of(rentToday));
      await bloc.dispatch(const AddEntryCleared());
      await type(bloc, '14000');
      expect(bloc.state.form.preview, const Option<SpendPreview>.none());
    });

    test('saving replaces the entry', () async {
      final AddEntryBloc bloc = build(editing: Option<Entry>.of(chai));
      await bloc.dispatch(const AddEntryKeyPressed('0'));
      await bloc.dispatch(const AddEntryNextPressed());
      await bloc.dispatch(const AddEntryCategoryPicked(SeedCategoryIds.food));
      expect(ledger.entries.firstWhere((Entry e) => e.id == chai.id).amount, Money.fromMajor(600));
    });

    test('Delete removes it and closes', () async {
      final AddEntryBloc bloc = build(editing: Option<Entry>.of(chai));
      await bloc.dispatch(const AddEntryDeleteRequested());
      expect(bloc.state, isA<AddEntryFinished>());
      expect(ledger.entries, isNot(contains(chai)));
    });

    test('a second Delete tap while deleting is dropped', () async {
      final Completer<void> slowDelete = Completer<void>();
      ledger.nextDeleteGate = slowDelete;
      final AddEntryBloc bloc = build(editing: Option<Entry>.of(chai))..add(const AddEntryDeleteRequested());
      await pumpEventQueue();
      bloc.add(const AddEntryDeleteRequested());
      await pumpEventQueue();
      slowDelete.complete();
      await pumpEventQueue();
      expect(bloc.state, isA<AddEntryFinished>());
      expect(haptics.events, <String>['success']);
    });

    test('a failed delete keeps the tray open', () async {
      ledger.failure = DatabaseFailure('locked');
      final AddEntryBloc bloc = build(editing: Option<Entry>.of(chai));
      await bloc.dispatch(const AddEntryDeleteRequested());
      expect(bloc.state, isA<AddEntryEditing>().having((AddEntryEditing s) => s.failed, 'failed', isTrue));
    });

    test('Delete does nothing when adding', () async {
      final AddEntryBloc bloc = build();
      await bloc.dispatch(const AddEntryDeleteRequested());
      expect(bloc.state, isA<AddEntryEditing>());
    });
  });

  test('events compare by their fields', () {
    expect(const AddEntryKindChanged(EntryKind.got).props, <Object?>[EntryKind.got]);
    expect(const AddEntryKeyPressed('5').props, <Object?>['5']);
    expect(const AddEntryQuickAdded(10).props, <Object?>[10]);
    expect(const AddEntryDateChanged(CalendarDate(2026, 10, 1)).props, <Object?>[const CalendarDate(2026, 10, 1)]);
    expect(const AddEntryNoteChanged('Chai').props, <Object?>['Chai']);
    expect(const AddEntryCategoryPicked(1).props, <Object?>[1]);
    expect(const AddEntryNextPressed().props, isEmpty);
  });

  group('AddEntryBloc new category (FR-AD-9, D138)', () {
    const Category petrol = Category(id: 13, key: 'own_13', iconKey: 'fuel', kind: EntryKind.spent, sort: 8, customName: 'Petrol');
    const Category gym = Category(id: 14, key: 'own_14', iconKey: 'gym', kind: EntryKind.spent, sort: 9, customName: 'Gym', hidden: true);
    final Map<int, String> labels = <int, String>{SeedCategoryIds.food: 'Food'};

    Future<AddEntryBloc> onNameStep() async {
      final AddEntryBloc bloc = build();
      await type(bloc, '250');
      await bloc.dispatch(const AddEntryNextPressed());
      await bloc.dispatch(const AddEntryNewCategoryOpened());
      return bloc;
    }

    test('the user\'s own tiles follow the 8 in order; hidden ones leave the tray', () {
      final EntryForm form = build(categories: <Category>[...seedCategories, gym, petrol]).state.form;
      expect(form.tiles.map((Category c) => c.key).skip(8), <String>['own_13']);
      expect(form.canAddOwn, isTrue);
    });

    test('with 4 of the user\'s own shown, no more can be added', () {
      final List<Category> four = <Category>[
        for (int i = 0; i < 4; i++)
          Category(id: 20 + i, key: 'own_${20 + i}', iconKey: 'tag', kind: EntryKind.spent, sort: 8 + i, customName: 'C$i'),
      ];
      expect(build(categories: <Category>[...seedCategories, ...four]).state.form.canAddOwn, isFalse);
    });

    test('Got never offers a new category', () {
      expect(build(kind: EntryKind.got).state.form.canAddOwn, isFalse);
    });

    test('New opens the name step with nothing typed and the icon following the name', () async {
      final EntryForm form = (await onNameStep()).state.form;
      expect((form.step, form.draftName, form.draftIcon), (AddEntryStep.newName, '', const Option<String>.none()));
      expect(form.draftIconKey, CategoryIcon.fallback);
    });

    test('typing a name picks its icon', () async {
      final AddEntryBloc bloc = await onNameStep();
      await bloc.dispatch(const AddEntryNewCategoryNameChanged('Petrol'));
      expect((bloc.state.form.draftName, bloc.state.form.draftIconKey), ('Petrol', 'fuel'));
    });

    test('a picked icon stays when the name changes, and back on the name step', () async {
      final AddEntryBloc bloc = await onNameStep();
      await bloc.dispatch(const AddEntryNewCategoryNameChanged('Petrol'));
      await bloc.dispatch(const AddEntryIconStepOpened());
      expect(bloc.state.form.step, AddEntryStep.newIcon);

      await bloc.dispatch(const AddEntryIconPicked('car'));
      await bloc.dispatch(const AddEntryNewCategoryNameChanged('Petrol pump'));

      expect((bloc.state.form.step, bloc.state.form.draftIconKey), (AddEntryStep.newName, 'car'));
    });

    test('picking the name\'s own icon goes back to following the name', () async {
      final AddEntryBloc bloc = await onNameStep();
      await bloc.dispatch(const AddEntryNewCategoryNameChanged('Petrol'));
      await bloc.dispatch(const AddEntryIconPicked('fuel'));
      expect(bloc.state.form.draftIcon, const Option<String>.none());
    });

    test('back goes icon step → name step → grid, keeping what was typed and the amount', () async {
      final AddEntryBloc bloc = await onNameStep();
      await bloc.dispatch(const AddEntryNewCategoryNameChanged('Petrol'));
      await bloc.dispatch(const AddEntryIconStepOpened());

      await bloc.dispatch(const AddEntryBackPressed());
      expect(bloc.state.form.step, AddEntryStep.newName);
      await bloc.dispatch(const AddEntryBackPressed());
      expect((bloc.state.form.step, bloc.state.form.draftName, bloc.state.form.rupees), (AddEntryStep.category, 'Petrol', 250));
    });

    test('Save in Petrol makes the category and saves the entry in it, then finishes', () async {
      final AddEntryBloc bloc = await onNameStep();
      await bloc.dispatch(const AddEntryNewCategoryNameChanged(' Petrol '));

      await bloc.dispatch(AddEntryNewCategorySaved(labels));

      final Category made = categoryRepository.categories.singleWhere((Category c) => c.isOwn);
      expect((made.customName, made.iconKey), ('Petrol', 'fuel'));
      expect(ledger.saved.single.categoryId, made.id);
      expect(ledger.saved.single.amount, Money.fromMajor(250));
      expect(bloc.state, isA<AddEntryFinished>());
      expect(haptics.events.last, 'success');
    });

    test('a name that matches a built-in category saves there and makes nothing', () async {
      final AddEntryBloc bloc = await onNameStep();
      await bloc.dispatch(const AddEntryNewCategoryNameChanged('food'));

      await bloc.dispatch(AddEntryNewCategorySaved(labels));

      expect(categoryRepository.categories.where((Category c) => c.isOwn), isEmpty);
      expect(ledger.saved.single.categoryId, SeedCategoryIds.food);
    });

    test('an empty name saves nothing', () async {
      final AddEntryBloc bloc = await onNameStep();
      await bloc.dispatch(const AddEntryNewCategoryNameChanged('   '));

      await bloc.dispatch(AddEntryNewCategorySaved(labels));

      expect(ledger.saved, isEmpty);
      expect(bloc.state, isA<AddEntryEditing>());
    });

    test('a refused category keeps the name step open with "Couldn\'t save" and nothing lost', () async {
      final AddEntryBloc bloc = await onNameStep();
      await bloc.dispatch(const AddEntryNewCategoryNameChanged('Petrol'));
      categoryRepository.failure = DatabaseFailure('locked');

      await bloc.dispatch(AddEntryNewCategorySaved(labels));

      final AddEntryState state = bloc.state;
      expect(state, isA<AddEntryEditing>().having((AddEntryEditing s) => s.failed, 'failed', isTrue));
      expect((state.form.step, state.form.draftName), (AddEntryStep.newName, 'Petrol'));
      expect(ledger.saved, isEmpty);
    });
  });
}
