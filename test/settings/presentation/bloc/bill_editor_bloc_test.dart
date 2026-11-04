import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/settings/presentation/bloc/bill_editor_bloc.dart';
import 'package:expense_tracker/settings/presentation/bloc/bill_editor_event.dart';
import 'package:expense_tracker/settings/presentation/bloc/bill_editor_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeRecurringRepository recurring;
  late FakeHaptics haptics;
  late BillEditorBloc bloc;

  BillEditorBloc build() {
    final FakeClock clock = FakeClock(WorkedExample.now);
    return BillEditorBloc(
      addBill: AddBill(recurring: recurring, categories: FakeCategoryRepository(), clock: clock),
      haptics: haptics,
    );
  }

  setUp(() {
    recurring = FakeRecurringRepository(WorkedExample.rules);
    haptics = FakeHaptics();
    bloc = build();
  });

  tearDown(() async {
    await bloc.close();
    await recurring.dispose();
  });

  BillEditorInProgress form() => bloc.state as BillEditorInProgress;

  Future<void> type(String digits) async {
    for (final String key in digits.split('')) {
      await bloc.dispatch(BillEditorKeyPressed(key));
    }
  }

  group('BillEditorBloc: adding (FR-SE-1)', () {
    test('starts on the name, empty', () {
      expect(bloc.state, const BillEditorInProgress());
    });

    test('a chip fills the name with a tick and stays on it; Next moves on (D86)', () async {
      await bloc.dispatch(const BillEditorKindPicked(BillKind.rent, 'Rent'));
      expect(form(), const BillEditorInProgress(label: 'Rent', kind: Option<BillKind>.of(BillKind.rent)));
      expect(haptics.events, <String>['tick']);
      await bloc.dispatch(const BillEditorNextPressed());
      expect(form().stage, BillEditorStage.amount);
    });

    test('typing a name forgets the chip', () async {
      await bloc.dispatch(const BillEditorKindPicked(BillKind.rent, 'Rent'));
      await bloc.dispatch(const BillEditorBackPressed());
      await bloc.dispatch(const BillEditorRenamed('Electricity'));
      expect((form().label, form().kind), ('Electricity', const Option<BillKind>.none()));
    });

    test('Next needs a name that isn\'t blank', () async {
      await bloc.dispatch(const BillEditorRenamed('   '));
      await bloc.dispatch(const BillEditorNextPressed());
      expect(form().stage, BillEditorStage.name);
      await bloc.dispatch(const BillEditorRenamed('Electricity'));
      await bloc.dispatch(const BillEditorNextPressed());
      expect(form().stage, BillEditorStage.amount);
    });

    test('Next needs an amount above ₹0', () async {
      await bloc.dispatch(const BillEditorKindPicked(BillKind.emi, 'EMI'));
      await bloc.dispatch(const BillEditorNextPressed());
      expect(form().stage, BillEditorStage.amount);
      await type('12');
      await bloc.dispatch(const BillEditorNextPressed());
      expect(form().stage, BillEditorStage.day);
    });

    test('the keypad builds the amount with a tick each, ⌫ and clear', () async {
      await bloc.dispatch(const BillEditorKindPicked(BillKind.phone, 'Phone'));
      await bloc.dispatch(const BillEditorNextPressed());
      await type('3990');
      await bloc.dispatch(const BillEditorBackspacePressed());
      expect(form().rupees, 399);
      await bloc.dispatch(const BillEditorCleared());
      expect(form().rupees, 0);
      expect(haptics.events, everyElement('tick'));
    });

    test('a 10th digit is refused with a shake and the reject haptic (FR-AD-2)', () async {
      await bloc.dispatch(const BillEditorKindPicked(BillKind.phone, 'Phone'));
      await bloc.dispatch(const BillEditorNextPressed());
      await type('999999999');
      await bloc.dispatch(const BillEditorKeyPressed('9'));
      expect((form().rupees, form().rejections), (999999999, 1));
      expect(haptics.events.last, 'reject');
    });

    test('keys do nothing on the name step', () async {
      await bloc.dispatch(const BillEditorKeyPressed('5'));
      expect(form().rupees, 0);
    });

    test('tapping a day saves the bill and finishes with the success haptic', () async {
      await bloc.dispatch(const BillEditorKindPicked(BillKind.internet, 'Internet'));
      await bloc.dispatch(const BillEditorNextPressed());
      await type('799');
      await bloc.dispatch(const BillEditorNextPressed());
      await bloc.dispatch(const BillEditorDayChosen(10));
      expect(bloc.state, const BillEditorSaved());
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
      await bloc.dispatch(const BillEditorKindPicked(BillKind.internet, 'Internet'));
      await bloc.dispatch(const BillEditorNextPressed());
      await type('799');
      await bloc.dispatch(const BillEditorNextPressed());
      await bloc.dispatch(const BillEditorDayChosen(10));
      await bloc.dispatch(const BillEditorNextPressed());
      await bloc.dispatch(const BillEditorBackPressed());
      expect(bloc.state, const BillEditorSaved());
    });

    test('rent saves under Home', () async {
      await bloc.dispatch(const BillEditorKindPicked(BillKind.rent, 'Rent'));
      await bloc.dispatch(const BillEditorNextPressed());
      await type('8200');
      await bloc.dispatch(const BillEditorNextPressed());
      await bloc.dispatch(const BillEditorDayChosen(5));
      expect(recurring.rules.last.categoryId, SeedCategoryIds.home);
    });

    test('a failed save stays open with everything kept, and says so (FR-AD-6)', () async {
      await bloc.dispatch(const BillEditorRenamed('Water'));
      await bloc.dispatch(const BillEditorNextPressed());
      await type('300');
      await bloc.dispatch(const BillEditorNextPressed());
      recurring.failure = DatabaseFailure('locked');
      await bloc.dispatch(const BillEditorDayChosen(3));
      expect(form(), const BillEditorInProgress(stage: BillEditorStage.day, label: 'Water', rupees: 300, saveFailed: true));
      expect(haptics.events.last, 'reject');
    });

    test('a second day tap while saving is dropped', () async {
      await bloc.dispatch(const BillEditorRenamed('Water'));
      await bloc.dispatch(const BillEditorNextPressed());
      await type('300');
      await bloc.dispatch(const BillEditorNextPressed());
      final Future<void> savingShown = expectLater(
        bloc.stream,
        emitsInOrder(<Object>[isA<BillEditorInProgress>().having((BillEditorInProgress s) => s.saving, 'saving', isTrue), const BillEditorSaved()]),
      );
      bloc
        ..add(const BillEditorDayChosen(3))
        ..add(const BillEditorDayChosen(4));
      await savingShown;
      await pumpEventQueue();
      expect(recurring.rules.where((RecurringRule r) => r.label == 'Water'), hasLength(1));
    });

    test('a day before the amount step does nothing', () async {
      await bloc.dispatch(const BillEditorDayChosen(3));
      expect(form().stage, BillEditorStage.name);
    });

    test('back steps day → amount → name, and stays on the name', () async {
      await bloc.dispatch(const BillEditorKindPicked(BillKind.rent, 'Rent'));
      await bloc.dispatch(const BillEditorNextPressed());
      await type('1');
      await bloc.dispatch(const BillEditorNextPressed());
      await bloc.dispatch(const BillEditorBackPressed());
      expect(form().stage, BillEditorStage.amount);
      await bloc.dispatch(const BillEditorBackPressed());
      expect(form().stage, BillEditorStage.name);
      await bloc.dispatch(const BillEditorBackPressed());
      expect(form().stage, BillEditorStage.name);
    });

    test('closing mid-save does not throw', () async {
      await bloc.dispatch(const BillEditorRenamed('Water'));
      await bloc.dispatch(const BillEditorNextPressed());
      await type('300');
      await bloc.dispatch(const BillEditorNextPressed());
      bloc.add(const BillEditorDayChosen(3));
      await expectLater(bloc.close(), completes);
    });
  });

  test('states compare by their fields', () {
    expect(const BillEditorSaved().props, isEmpty);
    expect(const BillEditorInProgress().copyWith(label: 'A'), const BillEditorInProgress(label: 'A'));
  });

  test('events compare by their fields', () {
    expect(const BillEditorKindPicked(BillKind.rent, 'Rent').props, <Object?>[BillKind.rent, 'Rent']);
    expect(const BillEditorRenamed('A').props, <Object?>['A']);
    expect(const BillEditorKeyPressed('5').props, <Object?>['5']);
    expect(const BillEditorDayChosen(3).props, <Object?>[3]);
    expect(const BillEditorNextPressed().props, isEmpty);
  });
}
