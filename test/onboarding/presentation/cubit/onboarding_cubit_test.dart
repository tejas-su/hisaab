import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/pay_rule.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/onboarding/data/mapper/onboarding_draft_mapper.dart';
import 'package:expense_tracker/onboarding/data/repository/onboarding_draft_repository_impl.dart';
import 'package:expense_tracker/onboarding/domain/entities/bill_draft.dart';
import 'package:expense_tracker/onboarding/domain/entities/onboarding_draft.dart';
import 'package:expense_tracker/onboarding/domain/entities/onboarding_step.dart';
import 'package:expense_tracker/onboarding/domain/entities/setup_labels.dart';
import 'package:expense_tracker/onboarding/domain/usecase/complete_onboarding.dart';
import 'package:expense_tracker/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:expense_tracker/onboarding/presentation/cubit/onboarding_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_app_preferences_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

const SetupLabels _labels = SetupLabels(income: 'Salary', bills: <BillKind, String>{BillKind.rent: 'Rent'});

void main() {
  late FakeAppPreferencesRepository preferences;
  late FakeRecurringRepository recurring;
  late FakeHaptics haptics;
  late OnboardingCubit cubit;

  OnboardingCubit build() {
    final FakeClock clock = FakeClock(WorkedExample.now);
    return OnboardingCubit(
      drafts: OnboardingDraftRepositoryImpl(preferences: preferences),
      completeOnboarding: CompleteOnboarding(
        categories: FakeCategoryRepository(),
        recurring: recurring,
        preferences: preferences,
        postDue: PostDueRecurring(recurring: recurring, clock: clock),
        clock: clock,
      ),
      haptics: haptics,
    );
  }

  setUp(() {
    preferences = FakeAppPreferencesRepository();
    recurring = FakeRecurringRepository();
    haptics = FakeHaptics();
    cubit = build();
  });

  tearDown(() => cubit.close());

  OnboardingInProgress progress() => cubit.state as OnboardingInProgress;
  OnboardingDraft saved() =>
      OnboardingDraftMapper.fromJson(preferences.draftJson ?? fail('nothing saved')).getOrElse((Failure f) => fail(f.message));

  Future<void> typeIncome(String digits) async {
    for (final String key in digits.split('')) {
      await cubit.pressKey(key);
    }
  }

  Future<void> reachBills() async {
    await cubit.start();
    await typeIncome('45000');
    await cubit.next();
    await cubit.choosePayRule(const MonthlyOnDay(4));
  }

  group('OnboardingCubit.start', () {
    test('starts loading', () => expect(cubit.state, const OnboardingLoading()));

    test('a fresh install starts at step 1 (FR-ON-2)', () async {
      await cubit.start();
      expect(cubit.state, const OnboardingInProgress(draft: OnboardingDraft()));
    });

    test('resumes a saved draft at its step (FR-ON-6)', () async {
      final OnboardingDraft draft = OnboardingDraft(step: OnboardingStep.bills, income: Money.fromMajor(45000));
      preferences.draftJson = OnboardingDraftMapper.toJson(draft);
      await cubit.start();
      expect(progress().draft, draft);
    });

    test('closing while the draft loads emits nothing', () async {
      final Future<void> starting = cubit.start();
      await cubit.close();
      await expectLater(starting, completes);
    });

    test('starts over when the draft can\'t be read', () async {
      preferences.failure = DatabaseFailure('locked');
      await cubit.start();
      expect(progress().draft, const OnboardingDraft());
    });
  });

  group('OnboardingCubit step 1: income', () {
    setUp(() => cubit.start());

    test('typing builds the amount, ticks once per key and saves the draft', () async {
      await typeIncome('45000');
      expect(progress().draft.income, Money.fromMajor(45000));
      expect(haptics.events, List<String>.filled(5, 'tick'));
      expect(saved().income, Money.fromMajor(45000));
    });

    test('a 10th digit is refused with the reject haptic and a shake', () async {
      await typeIncome('999999999');
      await cubit.pressKey('9');
      expect(progress().draft.income, Money.fromMajor(999999999));
      expect(progress().rejections, 1);
      expect(haptics.events.last, 'reject');
    });

    test('backspace drops a digit; clear empties it', () async {
      await typeIncome('450');
      await cubit.backspace();
      expect(progress().draft.income, Money.fromMajor(45));
      await cubit.clear();
      expect(progress().draft.income, Money.zero);
    });

    test('a failed draft save keeps the answer on screen', () async {
      preferences.failure = DatabaseFailure('locked');
      await typeIncome('7');
      expect(progress().draft.income, Money.fromMajor(7));
    });

    test('Next does nothing at ₹0', () async {
      await cubit.next();
      expect(progress().draft.step, OnboardingStep.income);
    });

    test('Next moves to step 2 once there is an amount', () async {
      await typeIncome('5');
      await cubit.next();
      expect(progress().draft.step, OnboardingStep.payday);
      expect(saved().step, OnboardingStep.payday);
    });
  });

  group('OnboardingCubit step 2: payday (FR-ON-3)', () {
    setUp(() async {
      await cubit.start();
      await typeIncome('45000');
      await cubit.next();
    });

    test('choosing a rule moves to step 3', () async {
      await cubit.choosePayRule(const LastDayOfMonth());
      expect(progress().draft.payRule, const Option<PayRule>.of(LastDayOfMonth()));
      expect(progress().draft.step, OnboardingStep.bills);
    });

    test('Pick a date and Every week open their pickers, and choosing closes them', () async {
      cubit.openPicker(PaydayPicker.dayOfMonth);
      expect(progress().picker, PaydayPicker.dayOfMonth);
      await cubit.choosePayRule(const MonthlyOnDay(25));
      expect(progress().picker, PaydayPicker.none);
    });

    test('keys are ignored outside step 1 and the bill keypad', () async {
      await cubit.pressKey('1');
      expect(progress().draft.income, Money.fromMajor(45000));
    });
  });

  group('OnboardingCubit step 3: bills (FR-ON-4)', () {
    setUp(reachBills);

    test('a bill chip opens the mini keypad, then the due day saves it', () async {
      cubit.openBill(BillKind.rent);
      await typeIncome('8200');
      expect(progress().billEditor.toNullable(), const BillEditor(kind: BillKind.rent, rupees: 8200));
      await cubit.next();
      expect(progress().billEditor.toNullable()?.stage, BillStage.day);
      await cubit.chooseBillDay(5);
      expect(progress().billEditor, const Option<BillEditor>.none());
      expect(progress().draft.bills, <BillDraft>[BillDraft(kind: BillKind.rent, amount: Money.fromMajor(8200), dueDay: 5)]);
      expect(saved().bills, hasLength(1));
      expect(progress().draft.income, Money.fromMajor(45000), reason: 'bill keys never touch income');
    });

    test('Next on an empty bill amount does nothing', () async {
      cubit.openBill(BillKind.phone);
      await cubit.next();
      expect(progress().billEditor.toNullable()?.stage, BillStage.amount);
    });

    test('the bill keypad refuses a 10th digit too', () async {
      cubit.openBill(BillKind.phone);
      await typeIncome('9999999999');
      expect(progress().billEditor.toNullable()?.rupees, 999999999);
      expect(progress().rejections, 1);
    });

    test('reopening an added bill prefills it, and removing drops it', () async {
      cubit.openBill(BillKind.rent);
      await typeIncome('8200');
      await cubit.next();
      await cubit.chooseBillDay(5);
      cubit.openBill(BillKind.rent);
      expect(progress().billEditor.toNullable()?.rupees, 8200);
      await cubit.removeBill(BillKind.rent);
      expect(progress().draft.bills, isEmpty);
      expect(progress().billEditor, const Option<BillEditor>.none());
    });

    test('backspace and clear work on the bill amount', () async {
      cubit.openBill(BillKind.rent);
      await typeIncome('820');
      await cubit.backspace();
      expect(progress().billEditor.toNullable()?.rupees, 82);
      await cubit.clear();
      expect(progress().billEditor.toNullable()?.rupees, 0);
    });
  });

  group('OnboardingCubit.back', () {
    setUp(reachBills);

    test('steps back one level at a time and reports when there is nowhere left', () async {
      cubit.openBill(BillKind.rent);
      await typeIncome('1');
      await cubit.next();
      expect(await cubit.back(), isTrue);
      expect(progress().billEditor.toNullable()?.stage, BillStage.amount);
      expect(await cubit.back(), isTrue);
      expect(progress().billEditor, const Option<BillEditor>.none());
      expect(await cubit.back(), isTrue);
      expect(progress().draft.step, OnboardingStep.payday);
      cubit.openPicker(PaydayPicker.weekday);
      expect(await cubit.back(), isTrue);
      expect(progress().picker, PaydayPicker.none);
      expect(await cubit.back(), isTrue);
      expect(progress().draft.step, OnboardingStep.income);
      expect(await cubit.back(), isFalse);
    });
  });

  group('OnboardingCubit.finish (FR-ON-5)', () {
    setUp(reachBills);

    test('emits [Finishing, Done] and plays the success haptic', () async {
      final Future<void> expectation =
          expectLater(cubit.stream, emitsInOrder(<Matcher>[isA<OnboardingFinishing>(), isA<OnboardingDone>()]));
      await cubit.finish(_labels);
      await expectation;
      expect(haptics.events.last, 'success');
      expect(preferences.done, isTrue);
    });

    test('a failed save keeps the answers and says so', () async {
      recurring.startFreshFailure = DatabaseFailure('disk full');
      await cubit.finish(_labels);
      expect(progress().saveFailed, isTrue);
      expect(progress().draft.payRule, const Option<PayRule>.of(MonthlyOnDay(4)));
    });

    test('a second tap while saving is ignored', () async {
      final Future<void> first = cubit.finish(_labels);
      await cubit.finish(_labels);
      await first;
      expect(recurring.setups, hasLength(1));
    });

    test('closing mid-save does not throw', () async {
      final Future<void> finishing = cubit.finish(_labels);
      await cubit.close();
      await expectLater(finishing, completes);
    });
  });

  test('methods before start do nothing', () async {
    await cubit.pressKey('1');
    await cubit.next();
    await cubit.finish(_labels);
    expect(await cubit.back(), isFalse);
    expect(cubit.state, const OnboardingLoading());
  });
}
