import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/amount_input.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/afford_answer.dart';
import 'package:hisaab/spends/domain/entities/saving_started.dart';
import 'package:hisaab/spends/domain/usecase/get_afford_inputs.dart';
import 'package:hisaab/spends/domain/usecase/start_saving_for.dart';
import 'package:hisaab/spends/presentation/bloc/afford_bloc.dart';
import 'package:hisaab/spends/presentation/bloc/afford_event.dart';
import 'package:hisaab/spends/presentation/bloc/afford_state.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/spends/afford_book.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late FakeHaptics haptics;
  late AffordBloc bloc;

  setUp(() {
    ledger = FakeLedgerRepository(AffordBook.history());
    recurring = FakeRecurringRepository(AffordBook.rules());
    haptics = FakeHaptics();
    final FakeClock clock = FakeClock(AffordBook.now);
    final FakeCategoryRepository categories = FakeCategoryRepository();
    bloc = AffordBloc(
      getInputs: GetAffordInputs(
        ledger: ledger,
        recurring: recurring,
        settings: FakeBudgetSettingsRepository(),
        periods: const PeriodCalculator(),
        clock: clock,
      ),
      startSaving: StartSavingFor(
        addBill: AddBill(recurring: recurring, categories: categories, clock: clock),
        editBill: EditBill(recurring: recurring, categories: categories, clock: clock),
        recurring: recurring,
      ),
      clock: clock,
      haptics: haptics,
    );
  });

  tearDown(() async {
    await bloc.close();
    ledger.dispose();
  });

  Future<void> type(String digits) async {
    for (final String key in digits.split('')) {
      await bloc.dispatch(AffordKeyPressed(key));
    }
  }

  Future<void> toHaveStep({String name = 'Mac', String price = '127000'}) async {
    await bloc.dispatch(AffordNameChanged(name));
    await type(price);
    await bloc.dispatch(const AffordNextPressed());
  }

  Future<void> toAnswer({String have = '60000'}) async {
    await toHaveStep();
    await bloc.dispatch(const AffordHaveChosen(true));
    await type(have);
    await bloc.dispatch(const AffordAnswerRequested());
  }

  AffordAnswered answered() => bloc.state as AffordAnswered;

  group('AffordBloc step 1 (FR-SP-9 AC-2)', () {
    test('starts on the item step with an empty draft', () {
      expect(bloc.state, const AffordItemStep());
    });

    test('digits build the price; ⌫ removes one and clear empties it', () async {
      await type('1270');
      expect(bloc.state.draft.price, 1270);
      await bloc.dispatch(const AffordBackspacePressed());
      expect(bloc.state.draft.price, 127);
      await bloc.dispatch(const AffordCleared());
      expect(bloc.state.draft.price, 0);
    });

    test('a 10th digit is refused at the 9-digit cap with the reject haptic', () async {
      await type('999999999');
      await bloc.dispatch(const AffordKeyPressed('9'));

      expect(bloc.state.draft.price, 999999999);
      expect(bloc.state.draft.rejections, 1);
      expect(haptics.events.last, 'reject');
    });

    test('Next is ignored at ₹0', () async {
      await bloc.dispatch(const AffordNameChanged('Mac'));
      await bloc.dispatch(const AffordNextPressed());

      expect(bloc.state, isA<AffordItemStep>());
    });

    test('Next is ignored with a name of only spaces and marks', () async {
      await bloc.dispatch(const AffordNameChanged('  -  '));
      await type('500');
      await bloc.dispatch(const AffordNextPressed());

      expect(bloc.state, isA<AffordItemStep>());
    });

    test('Next with a name and a price goes to step 2 with Nothing yet', () async {
      await toHaveStep();

      expect(bloc.state, const AffordHaveStep(AffordDraft(name: 'Mac', price: 127000)));
    });

    test('Next still goes on when the saving lookup fails, with nothing prefilled', () async {
      recurring.failure = DatabaseFailure('x');
      await toHaveStep();

      expect(bloc.state, const AffordHaveStep(AffordDraft(name: 'Mac', price: 127000)));
    });
  });

  group('AffordBloc step 2 (AC-3, D221)', () {
    test('the have-step is prefilled from a saving of the same name', () async {
      recurring.rules = <RecurringRule>[...AffordBook.rules(), AffordBook.mac()];
      ledger.entries.add(AffordBook.putIntoMac(60000));

      await toHaveStep(name: 'mac ');

      expect(bloc.state, isA<AffordHaveStep>());
      expect(bloc.state.draft.saidYes, isTrue);
      expect(bloc.state.draft.have, Money.fromMajor(60000));
    });

    test('Yes types the saved amount; Nothing yet keeps it but counts ₹0', () async {
      await toHaveStep();
      await bloc.dispatch(const AffordHaveChosen(true));
      await type('600');
      expect(bloc.state.draft.haveMoney, Money.fromMajor(600));

      await bloc.dispatch(const AffordHaveChosen(false));
      expect(bloc.state.draft.have, Money.fromMajor(600));
      expect(bloc.state.draft.haveMoney, Money.zero);
    });

    test('keys are ignored on step 2 until Yes is picked', () async {
      await toHaveStep();
      await type('5');

      expect(bloc.state.draft.have, Money.zero);
      expect(bloc.state.draft.price, 127000);
    });
  });

  group('AffordBloc answer (AC-4, BR-24 worked example)', () {
    test('emits [Loading, Answered] with the owner\'s example and done by 5 Dec 2027', () async {
      await toHaveStep();
      await bloc.dispatch(const AffordHaveChosen(true));
      await type('60000');
      final Future<void> expectation = expectLater(
        bloc.stream,
        emitsInOrder(<Matcher>[isA<AffordLoading>(), isA<AffordAnswered>()]),
      );

      await bloc.dispatch(const AffordAnswerRequested());
      await expectation;

      final AffordAnswered state = answered();
      expect(state.answer.verdict, AffordVerdict.saveUp);
      expect(state.answer.spare, Money.fromMajor(5000));
      expect(state.answer.need, Money.fromMajor(67000));
      expect(state.answer.putIns, const Option<int>.of(14));
      expect(state.doneBy, const Option<CalendarDate>.of(CalendarDate(2027, 12, 5)));
      expect(state.usual, Option<Money>.of(Money.fromMajor(750)));
      expect(state.existing, const Option<RecurringRule>.none());
      expect(state.waysOpen, isFalse);
    });

    test('a failed read emits AffordFailed', () async {
      await toHaveStep();
      recurring.failure = DatabaseFailure('x');

      await bloc.dispatch(const AffordAnswerRequested());

      expect(bloc.state, isA<AffordFailed>());
    });

    test('a newer answer request wins over an older, slower one', () async {
      await toHaveStep();
      final Completer<void> gate = Completer<void>();
      recurring.nextReadGate = gate;
      bloc.add(const AffordAnswerRequested());
      await pumpEventQueue();
      recurring.rules = AffordBook.rules(bills: 20000);
      await bloc.dispatch(const AffordAnswerRequested());
      gate.complete();
      await pumpEventQueue();

      expect(answered().answer.verdict, AffordVerdict.daysFull);
    });

    test('Back while the answer loads returns to step 2 and the answer never lands', () async {
      await toHaveStep();
      final Completer<void> gate = Completer<void>();
      recurring.nextReadGate = gate;
      bloc.add(const AffordAnswerRequested());
      await pumpEventQueue();
      await bloc.dispatch(const AffordBackPressed());
      gate.complete();
      await pumpEventQueue();

      expect(bloc.state, isA<AffordHaveStep>());
    });

    test('Other ways opens and closes', () async {
      await toAnswer();
      await bloc.dispatch(const AffordWaysToggled());
      expect(answered().waysOpen, isTrue);
      await bloc.dispatch(const AffordWaysToggled());
      expect(answered().waysOpen, isFalse);
    });

    test('a saving of the same name is kept on the answer for its Undo', () async {
      recurring.rules = <RecurringRule>[...AffordBook.rules(), AffordBook.mac()];
      await toAnswer();

      expect(answered().existing, Option<RecurringRule>.of(AffordBook.mac()));
    });
  });

  group('AffordBloc Start saving (AC-6, D220)', () {
    test('calls StartSavingFor with monthly = spare and target = need, then emits AffordSavingStarted', () async {
      await toAnswer();

      await bloc.dispatch(const AffordStartSavingPressed());

      final RecurringRule saved = recurring.rules.singleWhere((RecurringRule r) => r.label == 'Mac');
      expect(saved.amount, Money.fromMajor(5000));
      expect(saved.target, Option<Money>.of(Money.fromMajor(67000)));
      expect(saved.schedule.anchor.day, 5);
      expect(bloc.state, isA<AffordSavingStarted>());
      expect((bloc.state as AffordSavingStarted).started, SavingStarted(rule: saved, previous: const Option<RecurringRule>.none()));
      expect(haptics.events.last, 'success');
    });

    test('a second tap while the first save is in flight is dropped', () async {
      await toAnswer();
      final Completer<void> gate = Completer<void>();
      recurring.nextUpdateGate = gate;
      bloc
        ..add(const AffordStartSavingPressed())
        ..add(const AffordStartSavingPressed());
      await pumpEventQueue();
      gate.complete();
      await pumpEventQueue();

      expect(recurring.rules.where((RecurringRule r) => r.label == 'Mac'), hasLength(1));
      expect(recurring.updates, hasLength(1));
    });

    test('a re-check changes the same-name saving and remembers it as it was', () async {
      recurring.rules = <RecurringRule>[...AffordBook.rules(), AffordBook.mac()];
      await toAnswer();

      await bloc.dispatch(const AffordStartSavingPressed());

      final SavingStarted started = (bloc.state as AffordSavingStarted).started;
      expect(started.rule.id, AffordBook.macId);
      expect(started.previous, Option<RecurringRule>.of(AffordBook.mac()));
      expect(recurring.rules.where((RecurringRule r) => r.label == 'Mac'), hasLength(1));
    });

    test('a re-check of a saving holding ₹60,000 targets the whole price, and Savings agrees on the date', () async {
      recurring.rules = <RecurringRule>[...AffordBook.rules(), AffordBook.mac()];
      ledger.entries.add(AffordBook.putIntoMac(60000));
      await toHaveStep();
      await bloc.dispatch(const AffordAnswerRequested());
      final Option<CalendarDate> doneBy = answered().doneBy;

      await bloc.dispatch(const AffordStartSavingPressed());

      final RecurringRule saved = recurring.rules.singleWhere((RecurringRule r) => r.id == AffordBook.macId);
      expect(saved.target, Option<Money>.of(Money.fromMajor(127000)));
      expect(doneBy, const Option<CalendarDate>.of(CalendarDate(2027, 12, 5)));
      expect(
        SavingTarget.progress(target: Money.fromMajor(127000), setAside: Money.fromMajor(60000), saving: saved),
        TargetEstimate(doneBy.toNullable()!),
      );
    });

    test('a re-check with Nothing yet targets the price on top of what the saving holds', () async {
      recurring.rules = <RecurringRule>[...AffordBook.rules(), AffordBook.mac()];
      ledger.entries.add(AffordBook.putIntoMac(60000));
      await toHaveStep();
      await bloc.dispatch(const AffordHaveChosen(false));
      await bloc.dispatch(const AffordAnswerRequested());

      await bloc.dispatch(const AffordStartSavingPressed());

      final RecurringRule saved = recurring.rules.singleWhere((RecurringRule r) => r.id == AffordBook.macId);
      expect(saved.target, Option<Money>.of(Money.fromMajor(187000)));
    });

    test('a re-check at the 9-digit cap holding more than was typed keeps its target at the cap', () async {
      recurring.rules = <RecurringRule>[...AffordBook.rules(), AffordBook.mac()];
      ledger.entries.add(AffordBook.putIntoMac(60000));
      await toHaveStep(price: '${AmountInput.maxRupees}');
      await bloc.dispatch(const AffordHaveChosen(false));
      await bloc.dispatch(const AffordAnswerRequested());

      await bloc.dispatch(const AffordStartSavingPressed());

      final RecurringRule saved = recurring.rules.singleWhere((RecurringRule r) => r.id == AffordBook.macId);
      expect(saved.target, Option<Money>.of(Money.fromMajor(AmountInput.maxRupees)));
    });

    test('a saving holding paise is prefilled to the paisa, so its target is exactly the price', () async {
      recurring.rules = <RecurringRule>[...AffordBook.rules(), AffordBook.mac()];
      ledger.entries.add(AffordBook.putIntoMac(60000, paise: 50));
      await toHaveStep();
      expect(bloc.state.draft.have, const Money(6000050));
      await bloc.dispatch(const AffordAnswerRequested());

      await bloc.dispatch(const AffordStartSavingPressed());

      expect(recurring.rules.singleWhere((RecurringRule r) => r.id == AffordBook.macId).target, Option<Money>.of(Money.fromMajor(127000)));
    });

    test('a failed save keeps the answer, says so, and buzzes reject', () async {
      await toAnswer();
      recurring.failure = DatabaseFailure('x');

      await bloc.dispatch(const AffordStartSavingPressed());

      expect(answered().saveFailed, isTrue);
      expect(answered().saving, isFalse);
      expect(haptics.events.last, 'reject');
    });

    test('a retry after a half-made saving completes it and still undoes as a new saving', () async {
      await toAnswer();
      final Completer<void> gate = Completer<void>();
      recurring.nextUpdateGate = gate;
      bloc.add(const AffordStartSavingPressed());
      await pumpEventQueue();
      recurring.failure = DatabaseFailure('x');
      gate.complete();
      await pumpEventQueue();
      expect(answered().saveFailed, isTrue);
      recurring.failure = null;

      await bloc.dispatch(const AffordStartSavingPressed());

      expect(recurring.rules.where((RecurringRule r) => r.label == 'Mac'), hasLength(1));
      final SavingStarted started = (bloc.state as AffordSavingStarted).started;
      expect(started.rule.target, Option<Money>.of(Money.fromMajor(67000)));
      expect(started.previous, const Option<RecurringRule>.none());
    });

    test('Start saving is ignored on an answer that is not Not yet', () async {
      await toAnswer(have: '127000');

      await bloc.dispatch(const AffordStartSavingPressed());

      expect(answered().answer.verdict, AffordVerdict.fromSavings);
      expect(recurring.rules.where((RecurringRule r) => r.label == 'Mac'), isEmpty);
    });
  });

  group('AffordBloc Back (AC-7)', () {
    test('Back on the answer goes to step 2, keeping the draft', () async {
      await toAnswer();
      await bloc.dispatch(const AffordBackPressed());

      expect(bloc.state, AffordHaveStep(AffordDraft(name: 'Mac', price: 127000, saidYes: true, have: Money.fromMajor(60000))));
    });

    test('Back on step 2 goes to step 1', () async {
      await toHaveStep();
      await bloc.dispatch(const AffordBackPressed());

      expect(bloc.state, const AffordItemStep(AffordDraft(name: 'Mac', price: 127000)));
    });

    test('Back on a failed answer goes to step 2', () async {
      await toHaveStep();
      recurring.failure = DatabaseFailure('x');
      await bloc.dispatch(const AffordAnswerRequested());
      await bloc.dispatch(const AffordBackPressed());

      expect(bloc.state, isA<AffordHaveStep>());
    });

    test('Back on step 1 closes', () async {
      await bloc.dispatch(const AffordBackPressed());

      expect(bloc.state, isA<AffordClosed>());
    });

    test('See the answer is ignored off step 2', () async {
      await bloc.dispatch(const AffordAnswerRequested());

      expect(bloc.state, const AffordItemStep());
    });

    test('closing mid-answer does not throw', () async {
      await toHaveStep();
      bloc.add(const AffordAnswerRequested());

      await expectLater(bloc.close(), completes);
    });
  });

  group('AffordBloc values', () {
    test('events compare by value', () {
      expect(const AffordNameChanged('Mac').props, <Object?>['Mac']);
      expect(const AffordKeyPressed('5').props, <Object?>['5']);
      expect(const AffordHaveChosen(true).props, <Object?>[true]);
      expect(const AffordBackspacePressed().props, isEmpty);
    });

    test('states compare by value', () {
      final SavingStarted started = SavingStarted(rule: AffordBook.mac(), previous: const Option<RecurringRule>.none());

      expect(AffordSavingStarted(const AffordDraft(), started).props, <Object?>[const AffordDraft(), started]);
      expect(const AffordClosed(AffordDraft()).props, <Object?>[const AffordDraft()]);
    });
  });
}
