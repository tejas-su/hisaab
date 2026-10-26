import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/settings/presentation/cubit/bill_editor_cubit.dart';
import 'package:expense_tracker/settings/presentation/cubit/bill_editor_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeRecurringRepository recurring;
  late FakeHaptics haptics;
  late BillEditorCubit cubit;

  BillEditorCubit build({Option<RecurringRule> editing = const Option<RecurringRule>.none()}) {
    final FakeClock clock = FakeClock(WorkedExample.now);
    return BillEditorCubit(
      addBill: AddBill(recurring: recurring, categories: FakeCategoryRepository(), clock: clock),
      editBill: EditBill(recurring: recurring, clock: clock),
      haptics: haptics,
      editing: editing,
    );
  }

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    haptics = FakeHaptics();
    cubit = build();
  });

  tearDown(() async {
    await cubit.close();
    await recurring.dispose();
  });

  BillEditorInProgress form() => cubit.state as BillEditorInProgress;

  Future<void> type(String digits) async {
    for (final String key in digits.split('')) {
      await cubit.pressKey(key);
    }
  }

  group('BillEditorCubit: adding (FR-SE-1)', () {
    test('starts on the name, empty', () {
      expect(cubit.state, const BillEditorInProgress());
    });

    test('a chip fills the name and moves to the amount', () {
      cubit.pickKind(BillKind.rent, 'Rent');
      expect(form(), const BillEditorInProgress(stage: BillEditorStage.amount, label: 'Rent', kind: Option<BillKind>.of(BillKind.rent)));
    });

    test('typing a name forgets the chip', () {
      cubit
        ..pickKind(BillKind.rent, 'Rent')
        ..back()
        ..rename('Electricity');
      expect((form().label, form().kind), ('Electricity', const Option<BillKind>.none()));
    });

    test('Next needs a name that isn\'t blank', () {
      cubit
        ..rename('   ')
        ..next();
      expect(form().stage, BillEditorStage.name);
      cubit
        ..rename('Electricity')
        ..next();
      expect(form().stage, BillEditorStage.amount);
    });

    test('Next needs an amount above ₹0', () async {
      cubit
        ..pickKind(BillKind.emi, 'EMI')
        ..next();
      expect(form().stage, BillEditorStage.amount);
      await type('12');
      cubit.next();
      expect(form().stage, BillEditorStage.day);
    });

    test('the keypad builds the amount with a tick each, ⌫ and clear', () async {
      cubit.pickKind(BillKind.phone, 'Phone');
      await type('3990');
      await cubit.backspace();
      expect(form().rupees, 399);
      await cubit.clear();
      expect(form().rupees, 0);
      expect(haptics.events, everyElement('tick'));
    });

    test('a 10th digit is refused with a shake and the reject haptic (FR-AD-2)', () async {
      cubit.pickKind(BillKind.phone, 'Phone');
      await type('999999999');
      await cubit.pressKey('9');
      expect((form().rupees, form().rejections), (999999999, 1));
      expect(haptics.events.last, 'reject');
    });

    test('keys do nothing on the name step', () async {
      await cubit.pressKey('5');
      expect(form().rupees, 0);
    });

    test('tapping a day saves the bill and finishes with the success haptic', () async {
      cubit.pickKind(BillKind.internet, 'Internet');
      await type('799');
      cubit.next();
      await cubit.chooseDay(10);
      expect(cubit.state, const BillEditorSaved());
      expect(recurring.rules.last.draft, RecurringDraft(
        label: 'Internet',
        amount: Money.fromMajor(799),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.bills,
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 10)),
        nextDue: const CalendarDate(2026, 11, 10),
      ));
      expect(haptics.events.last, 'success');
    });

    test('nothing moves after the bill is saved', () async {
      cubit.pickKind(BillKind.internet, 'Internet');
      await type('799');
      cubit.next();
      await cubit.chooseDay(10);
      cubit.next();
      expect(cubit.back(), isFalse);
      expect(cubit.state, const BillEditorSaved());
    });

    test('rent saves under Home', () async {
      cubit.pickKind(BillKind.rent, 'Rent');
      await type('8200');
      cubit.next();
      await cubit.chooseDay(5);
      expect(recurring.rules.last.categoryId, SeedCategoryIds.home);
    });

    test('a failed save stays open with everything kept, and says so (FR-AD-6)', () async {
      cubit
        ..rename('Water')
        ..next();
      await type('300');
      cubit.next();
      recurring.failure = DatabaseFailure('locked');
      await cubit.chooseDay(3);
      expect(form(), const BillEditorInProgress(stage: BillEditorStage.day, label: 'Water', rupees: 300, saveFailed: true));
      expect(haptics.events.last, 'reject');
    });

    test('a second day tap while saving is ignored', () async {
      cubit
        ..rename('Water')
        ..next();
      await type('300');
      cubit.next();
      final Future<void> first = cubit.chooseDay(3);
      expect(form().saving, isTrue);
      await cubit.chooseDay(4);
      await first;
      expect(recurring.rules.where((RecurringRule r) => r.label == 'Water'), hasLength(1));
    });

    test('a day before the amount step does nothing', () async {
      await cubit.chooseDay(3);
      expect(form().stage, BillEditorStage.name);
    });

    test('back steps day → amount → name, then lets the page close', () async {
      cubit.pickKind(BillKind.rent, 'Rent');
      await type('1');
      cubit.next();
      expect(cubit.back(), isTrue);
      expect(form().stage, BillEditorStage.amount);
      expect(cubit.back(), isTrue);
      expect(form().stage, BillEditorStage.name);
      expect(cubit.back(), isFalse);
    });

    test('closing mid-save does not throw', () async {
      cubit
        ..rename('Water')
        ..next();
      await type('300');
      cubit.next();
      final Future<void> saving = cubit.chooseDay(3);
      await cubit.close();
      await expectLater(saving, completes);
    });
  });

  group('BillEditorCubit: editing', () {
    setUp(() async {
      await cubit.close();
      cubit = build(editing: Option<RecurringRule>.of(WorkedExample.electricity));
    });

    test('starts on the name, prefilled with the bill', () {
      expect(form(), const BillEditorInProgress(label: 'Electricity', rupees: 1200, isEditing: true));
    });

    test('saving changes the same bill', () async {
      cubit.next();
      await cubit.clear();
      await type('1500');
      cubit.next();
      await cubit.chooseDay(28);
      expect(cubit.state, const BillEditorSaved());
      expect(recurring.rules.last, WorkedExample.electricity.copyWith(
        amount: Money.fromMajor(1500),
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 28)),
        nextDue: const CalendarDate(2026, 10, 28),
      ));
    });
  });

  test('states compare by their fields', () {
    expect(const BillEditorSaved().props, isEmpty);
    expect(const BillEditorInProgress().copyWith(label: 'A'), const BillEditorInProgress(label: 'A'));
  });
}
