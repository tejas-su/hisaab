import 'dart:async';

import 'package:expense_tracker/ask_ai/domain/ask_goal.dart';
import 'package:expense_tracker/ask_ai/domain/chat_gpt_link.dart';
import 'package:expense_tracker/ask_ai/domain/entities/prompt_choice.dart';
import 'package:expense_tracker/ask_ai/domain/usecase/get_prompt_input.dart';
import 'package:expense_tracker/ask_ai/presentation/bloc/ask_ai_bloc.dart';
import 'package:expense_tracker/ask_ai/presentation/bloc/ask_ai_event.dart';
import 'package:expense_tracker/ask_ai/presentation/bloc/ask_ai_state.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_ai_handoff.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ask_ai/prompt_input.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

const String _golden =
    'You are a friendly money coach. Be specific, use my numbers, no jargon.\n'
    'Context: income ₹45,000/month (payday 4th), currency INR, period 2026-10-04..2026-11-03, today 2026-10-26.\n'
    'Spent ₹27,570, got ₹45,000. By category: Food 19,010; Home 8,200; Shopping 240; Travel 120.\n'
    'Recurring bills: Electricity 1,200 monthly on day 29; Rent 8,200 monthly on day 5.\n'
    '\n'
    'Entries (CSV):\n'
    'date,amount,kind,category,note\n'
    '2026-10-04,45000,got,Salary,\n'
    '2026-10-05,8200,spent,Home,\n'
    '2026-10-20,18950,spent,Food,\n'
    '2026-10-26,60,spent,Food,Chai & samosa\n'
    '2026-10-26,120,spent,Travel,Auto to office\n'
    '2026-10-26,240,spent,Shopping,Groceries\n'
    '\n'
    'Task: Review my month. Give: 1) the 3 biggest problems 2) 3 concrete savings with ₹ amounts 3) a budget per category for next month 4) one habit to change.';

Entry _lunch(int id) => Entry(
  id: id,
  amount: Money.fromMajor(150),
  kind: EntryKind.spent,
  categoryId: SeedCategoryIds.food,
  date: WorkedExample.today,
  createdAt: WorkedExample.now,
  note: 'Lunch',
);

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late FakeAiHandoff handoff;
  late FakeHaptics haptics;
  late AskAiBloc bloc;

  AskAiBloc build() => AskAiBloc(
    cycle: workedCycles.first,
    getInput: GetPromptInput(
      ledger: ledger,
      recurring: recurring,
      settings: FakeBudgetSettingsRepository(),
      categories: FakeCategoryRepository(),
      periods: const PeriodCalculator(),
      clock: FakeClock(WorkedExample.now),
    ),
    handoff: handoff,
    haptics: haptics,
    nameOf: englishName,
  );

  AskAiReady ready() => bloc.state as AskAiReady;

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    recurring = FakeRecurringRepository(WorkedExample.rules);
    handoff = FakeAiHandoff();
    haptics = FakeHaptics();
    bloc = build();
  });

  tearDown(() => bloc.close());

  group('AskAiBloc load (BR-15)', () {
    test('starts loading', () {
      expect(bloc.state, const AskAiLoading());
    });

    test('load emits Ready with the worked-example prompt', () async {
      await bloc.dispatch(const AskAiLoadRequested());
      expect(ready().choice, const PromptChoice());
      expect(ready().prompt.text, _golden);
      expect(ready().prompt.entryCount, 6);
      expect(ready().toasts, 0);
    });

    test('load failure emits Failed', () async {
      ledger.failure = DatabaseFailure('disk');
      await bloc.dispatch(const AskAiLoadRequested());
      expect(bloc.state, const AskAiFailed());
    });

    test('a second load during a slow one ends on the fresh data', () async {
      final Completer<void> slowRead = Completer<void>();
      ledger.nextReadGate = slowRead;
      bloc.add(const AskAiLoadRequested());
      await pumpEventQueue();
      ledger.entries.add(_lunch(7));
      await bloc.dispatch(const AskAiLoadRequested());
      slowRead.complete();
      await pumpEventQueue();
      expect(ready().prompt.entryCount, 7);
    });
  });

  test('choices before the prompt is ready change nothing', () async {
    await bloc.dispatch(const AskAiGoalChosen(AskGoal.helpMeSave));
    await bloc.dispatch(const AskAiQuestionChanged('Why?'));
    expect(bloc.state, const AskAiLoading());
    expect(haptics.events, isEmpty);
  });

  group('AskAiBloc choices (FR-AI-1, FR-AI-2)', () {
    setUp(() => bloc.dispatch(const AskAiLoadRequested()));

    test('choosing a goal rebuilds the task line and ticks', () async {
      await bloc.dispatch(const AskAiGoalChosen(AskGoal.helpMeSave));
      expect(ready().choice.goal, AskGoal.helpMeSave);
      expect(ready().prompt.text, endsWith('and the total I would save.'));
      expect(haptics.events, <String>['tick']);
    });

    test('choosing last three cycles widens the period without reloading', () async {
      ledger.entries.add(_lunch(7));
      await bloc.dispatch(const AskAiPeriodChosen(AskPeriod.lastThreeCycles));
      expect(ready().prompt.text, contains('period 2026-08-04..2026-11-03'));
      expect(ready().prompt.entryCount, 6);
      expect(haptics.events, <String>['tick']);
    });

    test('hiding notes rebuilds without the note column', () async {
      await bloc.dispatch(const AskAiNotesHidden(hide: true));
      expect(ready().choice.hideNotes, isTrue);
      expect(ready().prompt.text, isNot(contains('Chai')));
      expect(haptics.events, <String>['tick']);
    });

    test('typing a question rebuilds the task line without a tick', () async {
      await bloc.dispatch(const AskAiGoalChosen(AskGoal.ownQuestion));
      await bloc.dispatch(const AskAiQuestionChanged('Can I buy a bike?'));
      expect(ready().prompt.text, endsWith('Task: Can I buy a bike?'));
      expect(haptics.events, <String>['tick']);
    });

    test('a question longer than 200 is cut to 200', () async {
      await bloc.dispatch(AskAiQuestionChanged('a' * 250));
      expect(ready().choice.question, 'a' * 200);
    });
  });

  group('AskAiBloc hand-off (BR-15, FR-AI-4)', () {
    Future<void> load({bool short = false}) async {
      if (short) {
        ledger.entries
          ..clear()
          ..add(_lunch(1));
        recurring.rules = <RecurringRule>[];
      }
      await bloc.dispatch(const AskAiLoadRequested());
    }

    test('a blank own question makes every action do nothing', () async {
      await load();
      await bloc.dispatch(const AskAiGoalChosen(AskGoal.ownQuestion));
      await bloc.dispatch(const AskAiQuestionChanged('   '));
      await bloc.dispatch(const AskAiChatGptPressed());
      await bloc.dispatch(const AskAiOtherAiPressed());
      await bloc.dispatch(const AskAiCopyPressed());
      expect(handoff.copied, isEmpty);
      expect(handoff.opened, isEmpty);
      expect(handoff.shared, isEmpty);
      expect(ready().toasts, 0);
    });

    test('actions before the prompt is ready do nothing', () async {
      await bloc.dispatch(const AskAiCopyPressed());
      expect(handoff.copied, isEmpty);
    });

    test('ChatGPT with a short prompt copies, prefills and shows no toast', () async {
      await load(short: true);
      final String text = ready().prompt.text;
      expect(Uri.encodeComponent(text).length, lessThanOrEqualTo(ChatGptLink.maxEncodedLength));
      await bloc.dispatch(const AskAiChatGptPressed());
      expect(handoff.copied, <String>[text]);
      expect(handoff.opened, <Uri>[ChatGptLink.prefilled(text).getOrElse(() => fail('expected a link'))]);
      expect(ready().toasts, 0);
      expect(haptics.events, <String>['success']);
    });

    test('ChatGPT with a long prompt copies, opens chatgpt.com and toasts', () async {
      ledger.entries.addAll(List<Entry>.generate(40, (int i) => _lunch(10 + i)));
      await load();
      final String text = ready().prompt.text;
      expect(Uri.encodeComponent(text).length, greaterThan(ChatGptLink.maxEncodedLength));
      await bloc.dispatch(const AskAiChatGptPressed());
      expect(handoff.copied, <String>[text]);
      expect(handoff.opened, <Uri>[ChatGptLink.home]);
      expect(ready().toasts, 1);
    });

    test('ChatGPT when nothing opens the link still toasts', () async {
      await load(short: true);
      handoff.openResult = false;
      await bloc.dispatch(const AskAiChatGptPressed());
      expect(handoff.copied, hasLength(1));
      expect(ready().toasts, 1);
    });

    test('Other AI shares the exact text without a toast', () async {
      await load();
      await bloc.dispatch(const AskAiOtherAiPressed());
      expect(handoff.shared, <String>[_golden]);
      expect(handoff.copied, isEmpty);
      expect(ready().toasts, 0);
      expect(haptics.events, <String>['success']);
    });

    test('Copy only copies and toasts', () async {
      await load();
      await bloc.dispatch(const AskAiCopyPressed());
      expect(handoff.copied, <String>[_golden]);
      expect(handoff.opened, isEmpty);
      expect(ready().toasts, 1);
    });

    test('a second tap during the first hand-off is dropped', () async {
      await load();
      final Completer<void> slowCopy = Completer<void>();
      handoff.nextCopyGate = slowCopy;
      bloc
        ..add(const AskAiChatGptPressed())
        ..add(const AskAiChatGptPressed());
      await pumpEventQueue();
      slowCopy.complete();
      await pumpEventQueue();
      expect(handoff.copied, hasLength(1));
      expect(handoff.opened, hasLength(1));
    });

    test('closing mid-hand-off does not throw', () async {
      await load();
      final Completer<void> slowCopy = Completer<void>();
      handoff.nextCopyGate = slowCopy;
      bloc.add(const AskAiCopyPressed());
      await pumpEventQueue();
      final Future<void> closing = bloc.close();
      slowCopy.complete();
      await expectLater(closing, completes);
    });
  });

  test('prompt input fixture matches what the bloc loads', () async {
    await bloc.dispatch(const AskAiLoadRequested());
    expect(ready().input.cycles, workedCycles);
  });
}
