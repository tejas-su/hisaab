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
import 'package:expense_tracker/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:expense_tracker/onboarding/presentation/bloc/onboarding_event.dart';
import 'package:expense_tracker/onboarding/presentation/bloc/onboarding_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
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
  late OnboardingBloc bloc;

  OnboardingBloc build() {
    final FakeClock clock = FakeClock(WorkedExample.now);
    return OnboardingBloc(
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
    bloc = build();
  });

  tearDown(() => bloc.close());

  OnboardingInProgress progress() => bloc.state as OnboardingInProgress;
  OnboardingDraft saved() =>
      OnboardingDraftMapper.fromJson(preferences.draftJson ?? fail('nothing saved')).getOrElse((Failure f) => fail(f.message));

  Future<void> typeIncome(String digits) async {
    for (final String key in digits.split('')) {
      await bloc.dispatch(OnboardingKeyPressed(key));
    }
  }

  Future<void> reachBills() async {
    await bloc.dispatch(const OnboardingStarted());
    await typeIncome('45000');
    await bloc.dispatch(const OnboardingNextPressed());
    await bloc.dispatch(const OnboardingPayRuleChosen(MonthlyOnDay(4)));
  }

  group('OnboardingBloc start', () {
    test('starts loading', () => expect(bloc.state, const OnboardingLoading()));

    test('a fresh install starts at step 1 (FR-ON-2)', () async {
      await bloc.dispatch(const OnboardingStarted());
      expect(bloc.state, const OnboardingInProgress(draft: OnboardingDraft()));
    });

    test('resumes a saved draft at its step (FR-ON-6)', () async {
      final OnboardingDraft draft = OnboardingDraft(step: OnboardingStep.bills, income: Money.fromMajor(45000));
      preferences.draftJson = OnboardingDraftMapper.toJson(draft);
      await bloc.dispatch(const OnboardingStarted());
      expect(progress().draft, draft);
    });

    test('closing while the draft loads does not throw', () async {
      bloc.add(const OnboardingStarted());
      await expectLater(bloc.close(), completes);
    });

    test('starts over when the draft can\'t be read', () async {
      preferences.failure = DatabaseFailure('locked');
      await bloc.dispatch(const OnboardingStarted());
      expect(progress().draft, const OnboardingDraft());
    });
  });

  group('OnboardingBloc step 1: income', () {
    setUp(() => bloc.dispatch(const OnboardingStarted()));

    test('typing builds the amount, ticks once per key and saves the draft', () async {
      await typeIncome('45000');
      expect(progress().draft.income, Money.fromMajor(45000));
      expect(haptics.events, List<String>.filled(5, 'tick'));
      expect(saved().income, Money.fromMajor(45000));
    });

    test('a 10th digit is refused with the reject haptic and a shake', () async {
      await typeIncome('999999999');
      await bloc.dispatch(const OnboardingKeyPressed('9'));
      expect(progress().draft.income, Money.fromMajor(999999999));
      expect(progress().rejections, 1);
      expect(haptics.events.last, 'reject');
    });

    test('backspace drops a digit; clear empties it', () async {
      await typeIncome('450');
      await bloc.dispatch(const OnboardingBackspacePressed());
      expect(progress().draft.income, Money.fromMajor(45));
      await bloc.dispatch(const OnboardingCleared());
      expect(progress().draft.income, Money.zero);
    });

    test('a failed draft save keeps the answer on screen', () async {
      preferences.failure = DatabaseFailure('locked');
      await typeIncome('7');
      expect(progress().draft.income, Money.fromMajor(7));
    });

    test('Next does nothing at ₹0', () async {
      await bloc.dispatch(const OnboardingNextPressed());
      expect(progress().draft.step, OnboardingStep.income);
    });

    test('Next moves to step 2 once there is an amount', () async {
      await typeIncome('5');
      await bloc.dispatch(const OnboardingNextPressed());
      expect(progress().draft.step, OnboardingStep.payday);
      expect(saved().step, OnboardingStep.payday);
    });
  });

  group('OnboardingBloc step 2: payday (FR-ON-3)', () {
    setUp(() async {
      await bloc.dispatch(const OnboardingStarted());
      await typeIncome('45000');
      await bloc.dispatch(const OnboardingNextPressed());
    });

    test('choosing a rule moves to step 3', () async {
      await bloc.dispatch(const OnboardingPayRuleChosen(LastDayOfMonth()));
      expect(progress().draft.payRule, const Option<PayRule>.of(LastDayOfMonth()));
      expect(progress().draft.step, OnboardingStep.bills);
    });

    test('Pick a date and Every week open their pickers, and choosing closes them', () async {
      await bloc.dispatch(const OnboardingPickerOpened(PaydayPicker.dayOfMonth));
      expect(progress().picker, PaydayPicker.dayOfMonth);
      await bloc.dispatch(const OnboardingPayRuleChosen(MonthlyOnDay(25)));
      expect(progress().picker, PaydayPicker.none);
    });

    test('keys are ignored outside step 1 and the bill keypad', () async {
      await bloc.dispatch(const OnboardingKeyPressed('1'));
      expect(progress().draft.income, Money.fromMajor(45000));
    });
  });

  group('OnboardingBloc step 3: bills (FR-ON-4)', () {
    setUp(reachBills);

    test('a bill chip opens the mini keypad, then the due day saves it', () async {
      await bloc.dispatch(const OnboardingBillOpened(BillKind.rent));
      await typeIncome('8200');
      expect(progress().billEditor.toNullable(), const BillEditor(kind: BillKind.rent, rupees: 8200));
      await bloc.dispatch(const OnboardingNextPressed());
      expect(progress().billEditor.toNullable()?.stage, BillStage.day);
      await bloc.dispatch(const OnboardingBillDayChosen(5));
      expect(progress().billEditor, const Option<BillEditor>.none());
      expect(progress().draft.bills, <BillDraft>[BillDraft(kind: BillKind.rent, amount: Money.fromMajor(8200), dueDay: 5)]);
      expect(saved().bills, hasLength(1));
      expect(progress().draft.income, Money.fromMajor(45000), reason: 'bill keys never touch income');
    });

    test('Next on an empty bill amount does nothing', () async {
      await bloc.dispatch(const OnboardingBillOpened(BillKind.phone));
      await bloc.dispatch(const OnboardingNextPressed());
      expect(progress().billEditor.toNullable()?.stage, BillStage.amount);
    });

    test('the bill keypad refuses a 10th digit too', () async {
      await bloc.dispatch(const OnboardingBillOpened(BillKind.phone));
      await typeIncome('9999999999');
      expect(progress().billEditor.toNullable()?.rupees, 999999999);
      expect(progress().rejections, 1);
    });

    test('reopening an added bill prefills it, and removing drops it', () async {
      await bloc.dispatch(const OnboardingBillOpened(BillKind.rent));
      await typeIncome('8200');
      await bloc.dispatch(const OnboardingNextPressed());
      await bloc.dispatch(const OnboardingBillDayChosen(5));
      await bloc.dispatch(const OnboardingBillOpened(BillKind.rent));
      expect(progress().billEditor.toNullable()?.rupees, 8200);
      await bloc.dispatch(const OnboardingBillRemoved(BillKind.rent));
      expect(progress().draft.bills, isEmpty);
      expect(progress().billEditor, const Option<BillEditor>.none());
    });

    test('backspace and clear work on the bill amount', () async {
      await bloc.dispatch(const OnboardingBillOpened(BillKind.rent));
      await typeIncome('820');
      await bloc.dispatch(const OnboardingBackspacePressed());
      expect(progress().billEditor.toNullable()?.rupees, 82);
      await bloc.dispatch(const OnboardingCleared());
      expect(progress().billEditor.toNullable()?.rupees, 0);
    });
  });

  group('OnboardingBloc back', () {
    setUp(reachBills);

    test('steps back one level at a time and stays put on step 1', () async {
      await bloc.dispatch(const OnboardingBillOpened(BillKind.rent));
      await typeIncome('1');
      await bloc.dispatch(const OnboardingNextPressed());
      await bloc.dispatch(const OnboardingBackPressed());
      expect(progress().billEditor.toNullable()?.stage, BillStage.amount);
      await bloc.dispatch(const OnboardingBackPressed());
      expect(progress().billEditor, const Option<BillEditor>.none());
      await bloc.dispatch(const OnboardingBackPressed());
      expect(progress().draft.step, OnboardingStep.payday);
      await bloc.dispatch(const OnboardingPickerOpened(PaydayPicker.weekday));
      await bloc.dispatch(const OnboardingBackPressed());
      expect(progress().picker, PaydayPicker.none);
      await bloc.dispatch(const OnboardingBackPressed());
      expect(progress().draft.step, OnboardingStep.income);
      final OnboardingState onStepOne = bloc.state;
      await bloc.dispatch(const OnboardingBackPressed());
      expect(bloc.state, onStepOne);
    });
  });

  group('OnboardingBloc finish (FR-ON-5)', () {
    setUp(reachBills);

    test('emits [Finishing, Done] and plays the success haptic', () async {
      final Future<void> expectation =
          expectLater(bloc.stream, emitsInOrder(<Matcher>[isA<OnboardingFinishing>(), isA<OnboardingDone>()]));
      await bloc.dispatch(const OnboardingFinishRequested(_labels));
      await expectation;
      expect(haptics.events.last, 'success');
      expect(preferences.done, isTrue);
    });

    test('a failed save keeps the answers and says so', () async {
      recurring.startFreshFailure = DatabaseFailure('disk full');
      await bloc.dispatch(const OnboardingFinishRequested(_labels));
      expect(progress().saveFailed, isTrue);
      expect(progress().draft.payRule, const Option<PayRule>.of(MonthlyOnDay(4)));
    });

    test('a second tap while saving is ignored', () async {
      bloc
        ..add(const OnboardingFinishRequested(_labels))
        ..add(const OnboardingFinishRequested(_labels));
      await pumpEventQueue();
      expect(recurring.setups, hasLength(1));
    });

    test('closing mid-save does not throw', () async {
      bloc.add(const OnboardingFinishRequested(_labels));
      await expectLater(bloc.close(), completes);
    });
  });

  test('events before start do nothing', () async {
    await bloc.dispatch(const OnboardingKeyPressed('1'));
    await bloc.dispatch(const OnboardingNextPressed());
    await bloc.dispatch(const OnboardingFinishRequested(_labels));
    await bloc.dispatch(const OnboardingBackPressed());
    expect(bloc.state, const OnboardingLoading());
  });

  test('events compare by their fields', () {
    expect(const OnboardingStarted().props, isEmpty);
    expect(const OnboardingKeyPressed('1').props, <Object?>['1']);
    expect(const OnboardingPickerOpened(PaydayPicker.weekday).props, <Object?>[PaydayPicker.weekday]);
    expect(const OnboardingPayRuleChosen(LastDayOfMonth()).props, <Object?>[const LastDayOfMonth()]);
    expect(const OnboardingBillOpened(BillKind.rent).props, <Object?>[BillKind.rent]);
    expect(const OnboardingBillDayChosen(5).props, <Object?>[5]);
    expect(const OnboardingBillRemoved(BillKind.rent).props, <Object?>[BillKind.rent]);
    expect(const OnboardingFinishRequested(_labels).props, <Object?>[_labels]);
  });
}
