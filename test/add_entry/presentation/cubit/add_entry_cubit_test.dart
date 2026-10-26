import 'package:expense_tracker/add_entry/presentation/cubit/add_entry_cubit.dart';
import 'package:expense_tracker/add_entry/presentation/cubit/add_entry_state.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:expense_tracker/core/usecases/use_case.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_budget_settings_repository.dart';
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

  setUp(() async {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    haptics = FakeHaptics();
    clock = FakeClock(WorkedExample.now);
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

  AddEntryCubit build({Option<Entry> editing = const Option<Entry>.none(), EntryKind kind = EntryKind.spent, bool withSummary = true}) {
    final AddEntryCubit cubit = AddEntryCubit(
      saveEntry: SaveEntry(ledger: ledger, clock: clock),
      deleteEntry: DeleteEntry(ledger: ledger),
      haptics: haptics,
      clock: clock,
      categories: seedCategories,
      summary: withSummary ? Option<CycleSummary>.of(summary) : const Option<CycleSummary>.none(),
      editing: editing,
      kind: kind,
    );
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> type(AddEntryCubit cubit, String digits) async {
    for (final String key in digits.split('')) {
      cubit.pressKey(key);
    }
  }

  group('AddEntryCubit step 1: amount (FR-AD-1 to FR-AD-4)', () {
    test('opens on Spent with the 8 Spent tiles, today, and no amount', () {
      final EntryForm form = build().state.form;
      expect((form.kind, form.rupees, form.date, form.step), (EntryKind.spent, 0, WorkedExample.today, AddEntryStep.amount));
      expect(form.tiles.map((Category c) => c.key), <String>['food', 'travel', 'shopping', 'bills', 'fun', 'health', 'home', 'other']);
      expect(form.earliestDate, const CalendarDate(2026, 9, 4));
    });

    test('typing shows live digits with one tick each', () async {
      final AddEntryCubit cubit = build();
      await type(cubit, '2450');
      expect(cubit.state.form.rupees, 2450);
      expect(haptics.events, List<String>.filled(4, 'tick'));
    });

    test('a 10th digit is rejected with a shake and the reject haptic', () async {
      final AddEntryCubit cubit = build();
      await type(cubit, '9999999999');
      expect(cubit.state.form.rupees, 999999999);
      expect((cubit.state as AddEntryEditing).rejections, 1);
      expect(haptics.events.last, 'reject');
    });

    test('quick chips add to the amount (+₹10 then +₹50)', () {
      final AddEntryCubit cubit = build()
        ..quickAdd(10)
        ..quickAdd(50);
      expect(cubit.state.form.rupees, 60);
    });

    test('a quick chip past the cap is rejected', () async {
      final AddEntryCubit cubit = build();
      await type(cubit, '999999999');
      cubit.quickAdd(10);
      expect((cubit.state as AddEntryEditing).rejections, 1);
    });

    test('backspace and long-press clear', () async {
      final AddEntryCubit cubit = build();
      await type(cubit, '245');
      cubit.backspace();
      expect(cubit.state.form.rupees, 24);
      cubit.clear();
      expect(cubit.state.form.rupees, 0);
    });

    test('the preview shows what is left today (FR-AD-3)', () async {
      final AddEntryCubit cubit = build();
      await type(cubit, '1000');
      expect(cubit.state.form.preview, Option<SpendPreview>.of(FitsToday(Money.fromMajor(430))));
    });

    test('the preview shows the overspend and tomorrow\'s share', () async {
      final AddEntryCubit cubit = build();
      await type(cubit, '2450');
      expect(
        cubit.state.form.preview,
        Option<SpendPreview>.of(OverTodayShare(over: Money.fromMajor(1020), tomorrow: Option<Money>.of(Money.fromMajor(1722)))),
      );
    });

    test('no preview for Got, at ₹0, or without a summary', () async {
      final AddEntryCubit got = build(kind: EntryKind.got);
      await type(got, '500');
      expect(got.state.form.preview, const Option<SpendPreview>.none());
      expect(build().state.form.preview, const Option<SpendPreview>.none());
      final AddEntryCubit noSummary = build(withSummary: false);
      await type(noSummary, '5');
      expect(noSummary.state.form.preview, const Option<SpendPreview>.none());
      expect(noSummary.state.form.earliestDate, WorkedExample.today.addDays(-AddEntryCubit.fallbackHistoryDays));
    });

    test('switching to Got shows the Got tiles and drops the preview', () async {
      final AddEntryCubit cubit = build();
      await type(cubit, '500');
      cubit.setKind(EntryKind.got);
      expect(cubit.state.form.tiles.map((Category c) => c.key), <String>['salary', 'other_income']);
      expect(cubit.state.form.preview, const Option<SpendPreview>.none());
      expect(cubit.state.form.rupees, 500);
    });

    test('Next needs an amount, then opens step 2 (FR-AD-4)', () async {
      final AddEntryCubit cubit = build()..next();
      expect(cubit.state.form.step, AddEntryStep.amount);
      cubit
        ..pressKey('5')
        ..next();
      expect(cubit.state.form.step, AddEntryStep.category);
    });

    test('Back from step 2 keeps the amount; back from step 1 closes (FR-AD-7)', () {
      final AddEntryCubit cubit = build()
        ..pressKey('5')
        ..next();
      expect(cubit.back(), isTrue);
      expect((cubit.state.form.step, cubit.state.form.rupees), (AddEntryStep.amount, 5));
      expect(cubit.back(), isFalse);
    });
  });

  group('AddEntryCubit step 2: save (FR-AD-5, FR-AD-6)', () {
    test('tapping a tile saves, flashes that tile, then finishes with the success haptic', () async {
      final AddEntryCubit cubit = build()
        ..pressKey('6')
        ..pressKey('0')
        ..next()
        ..setNote('  Chai  ');
      final Future<void> expectation = expectLater(
        cubit.stream,
        emitsInOrder(<Matcher>[
          isA<AddEntrySaving>().having((AddEntrySaving s) => s.categoryId, 'categoryId', SeedCategoryIds.food),
          isA<AddEntryFinished>(),
        ]),
      );
      await cubit.pickCategory(SeedCategoryIds.food);
      await expectation;
      expect(ledger.saved.single, EntryDraft(amount: Money.fromMajor(60), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today, note: 'Chai'));
      expect(haptics.events.last, 'success');
    });

    test('a second tap while saving is ignored', () async {
      final AddEntryCubit cubit = build()
        ..pressKey('6')
        ..next();
      final Future<void> first = cubit.pickCategory(SeedCategoryIds.food);
      await cubit.pickCategory(SeedCategoryIds.travel);
      await first;
      expect(ledger.saved, hasLength(1));
    });

    test('a failed save keeps everything and says so', () async {
      ledger.failure = DatabaseFailure('disk full');
      final AddEntryCubit cubit = build()
        ..pressKey('6')
        ..next();
      await cubit.pickCategory(SeedCategoryIds.food);
      expect(cubit.state, isA<AddEntryEditing>().having((AddEntryEditing s) => s.failed, 'failed', isTrue));
      expect(cubit.state.form.rupees, 6);
      expect(haptics.events.last, 'reject');
    });

    test('the date can be yesterday but never before the earliest date or after today', () {
      final AddEntryCubit cubit = build()..setDate(WorkedExample.today.addDays(-1));
      expect(cubit.state.form.date, WorkedExample.today.addDays(-1));
      cubit.setDate(const CalendarDate(2020, 1, 1));
      expect(cubit.state.form.date, const CalendarDate(2026, 9, 4));
      cubit.setDate(WorkedExample.today.addDays(3));
      expect(cubit.state.form.date, WorkedExample.today);
    });

    test('a back-dated entry has no today preview', () {
      final AddEntryCubit cubit = build()
        ..pressKey('6')
        ..setDate(WorkedExample.today.addDays(-1));
      expect(cubit.state.form.preview, const Option<SpendPreview>.none());
    });

    test('keys and edits are ignored while saving', () async {
      final AddEntryCubit cubit = build()
        ..pressKey('6')
        ..next();
      final Future<void> saving = cubit.pickCategory(SeedCategoryIds.food);
      cubit
        ..pressKey('1')
        ..setNote('late');
      expect(cubit.state.form.rupees, 6);
      expect(cubit.state.form.note, '');
      await saving;
    });

    test('closing mid-delete does not throw', () async {
      final AddEntryCubit cubit = build(editing: Option<Entry>.of(WorkedExample.entries[3]));
      final Future<void> deleting = cubit.delete();
      await cubit.close();
      await expectLater(deleting, completes);
    });

    test('closing mid-save does not throw', () async {
      final AddEntryCubit cubit = build()
        ..pressKey('6')
        ..next();
      final Future<void> saving = cubit.pickCategory(SeedCategoryIds.food);
      await cubit.close();
      await expectLater(saving, completes);
    });
  });

  group('AddEntryCubit edit mode (FR-AD-8)', () {
    final Entry chai = WorkedExample.entries[3];

    test('opens on step 1 prefilled with the entry', () {
      final EntryForm form = build(editing: Option<Entry>.of(chai)).state.form;
      expect((form.rupees, form.kind, form.note, form.date), (60, EntryKind.spent, 'Chai & samosa', chai.date));
    });

    test('previews only the change in amount', () async {
      final AddEntryCubit cubit = build(editing: Option<Entry>.of(chai))
        ..clear()
        ..pressKey('1')
        ..pressKey('6')
        ..pressKey('0');
      expect(cubit.state.form.preview, Option<SpendPreview>.of(FitsToday(Money.fromMajor(1330))));
    });

    test('saving replaces the entry', () async {
      final AddEntryCubit cubit = build(editing: Option<Entry>.of(chai))
        ..pressKey('0')
        ..next();
      await cubit.pickCategory(SeedCategoryIds.food);
      expect(ledger.entries.firstWhere((Entry e) => e.id == chai.id).amount, Money.fromMajor(600));
    });

    test('Delete removes it and closes', () async {
      final AddEntryCubit cubit = build(editing: Option<Entry>.of(chai));
      await cubit.delete();
      expect(cubit.state, isA<AddEntryFinished>());
      expect(ledger.entries, isNot(contains(chai)));
    });

    test('a failed delete keeps the tray open', () async {
      ledger.failure = DatabaseFailure('locked');
      final AddEntryCubit cubit = build(editing: Option<Entry>.of(chai));
      await cubit.delete();
      expect(cubit.state, isA<AddEntryEditing>().having((AddEntryEditing s) => s.failed, 'failed', isTrue));
    });

    test('Delete does nothing when adding', () async {
      final AddEntryCubit cubit = build();
      await cubit.delete();
      expect(cubit.state, isA<AddEntryEditing>());
    });
  });
}
