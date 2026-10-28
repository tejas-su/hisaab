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
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
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
    'You are a friendly money coach for someone in India. Reply in simple English, under 200 words.\n'
    'Use only the numbers below. Write amounts in ₹ with Indian grouping (₹1,25,000).\n'
    "If there is too little data to judge, say so. Don't name specific stocks, funds, loans or apps.\n"
    'Context: income ₹45,000/month (payday 4th), currency INR, period 2026-10-04..2026-11-03, today 2026-10-26.\n'
    'From my app, and correct: safe to spend today ₹1,430; at this pace it lasts till payday with about ₹9,300 spare.\n'
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
    'Task: Tell me how this period went. Give: 1) 3 things that stand out, good or bad, with ₹ amounts 2) the one change that would save the most, and how much a month 3) one habit worth keeping.';

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
  late FakeClock clock;
  late AskAiBloc bloc;

  AskAiBloc build({PayCycle? cycle}) => AskAiBloc(
    cycle: cycle ?? workedCycles.first,
    getInput: GetPromptInput(
      ledger: ledger,
      recurring: recurring,
      settings: FakeBudgetSettingsRepository(),
      categories: FakeCategoryRepository(),
      periods: const PeriodCalculator(),
      clock: clock,
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
    clock = FakeClock(WorkedExample.now);
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
      expect(ready().prompt.text, endsWith('other fixed bills or health.'));
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
      expect(ready().prompt.text, endsWith('My question: Can I buy a bike?'));
      expect(haptics.events, <String>['tick']);
    });

    test('typing a question picks Ask my own question', () async {
      await bloc.dispatch(const AskAiQuestionChanged('Can I buy a bike?'));
      expect(ready().choice.goal, AskGoal.ownQuestion);
      expect(ready().prompt.text, endsWith('My question: Can I buy a bike?'));
    });

    test('clearing the question keeps the goal, so the actions wait for text', () async {
      await bloc.dispatch(const AskAiQuestionChanged('Why?'));
      await bloc.dispatch(const AskAiQuestionChanged(''));
      expect(ready().choice.goal, AskGoal.ownQuestion);
      expect(ready().choice.canSend, isFalse);
    });

    test('the current cycle with a payday offers Will my money last till payday?', () async {
      await bloc.dispatch(const AskAiGoalChosen(AskGoal.onTrack));
      expect(ready().choice.goal, AskGoal.onTrack);
    });

    test('a question longer than 200 is cut to 200', () async {
      await bloc.dispatch(AskAiQuestionChanged('a' * 250));
      expect(ready().choice.question, 'a' * 200);
    });
  });

  group('AskAiBloc on-track goal (FR-AI-1)', () {
    test('a past cycle falls back to the default goal', () async {
      await bloc.close();
      bloc = build(cycle: workedCycles[1]);
      await bloc.dispatch(const AskAiLoadRequested());
      await bloc.dispatch(const AskAiGoalChosen(AskGoal.onTrack));
      expect(ready().choice.goal, const PromptChoice().goal);
      expect(ready().prompt.text, isNot(contains('Will my money last')));
    });

    test('income with no fixed payday falls back to the default goal', () async {
      recurring.rules = <RecurringRule>[WorkedExample.rent];
      await bloc.close();
      bloc = build(cycle: const PayCycle(start: CalendarDate(2026, 10, 1), end: CalendarDate(2026, 10, 31)));
      await bloc.dispatch(const AskAiLoadRequested());
      await bloc.dispatch(const AskAiGoalChosen(AskGoal.onTrack));
      expect(ready().choice.goal, const PromptChoice().goal);
    });

    test('a reload after payday drops the pick that is no longer offered', () async {
      await bloc.dispatch(const AskAiLoadRequested());
      await bloc.dispatch(const AskAiGoalChosen(AskGoal.onTrack));
      clock.current = DateTime(2026, 11, 4, 9);
      await bloc.dispatch(const AskAiLoadRequested());
      expect(ready().choice.goal, const PromptChoice().goal);
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

    test('a short prompt needs no paste', () async {
      await load(short: true);
      expect(ready().needsPaste, isFalse);
    });

    test('ChatGPT with a long prompt copies and opens chatgpt.com; the caption said to paste, so no toast', () async {
      ledger.entries.addAll(List<Entry>.generate(40, (int i) => _lunch(10 + i)));
      await load();
      final String text = ready().prompt.text;
      expect(Uri.encodeComponent(text).length, greaterThan(ChatGptLink.maxEncodedLength));
      expect(ready().needsPaste, isTrue);
      await bloc.dispatch(const AskAiChatGptPressed());
      expect(handoff.copied, <String>[text]);
      expect(handoff.opened, <Uri>[ChatGptLink.home]);
      expect(ready().toasts, 0);
    });

    test('ChatGPT with a long prompt when nothing opens chatgpt.com toasts', () async {
      ledger.entries.addAll(List<Entry>.generate(40, (int i) => _lunch(10 + i)));
      await load();
      handoff.openResult = false;
      await bloc.dispatch(const AskAiChatGptPressed());
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
