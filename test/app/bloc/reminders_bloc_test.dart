import 'dart:async';

import 'package:hisaab/app/bloc/reminders_bloc.dart';
import 'package:hisaab/app/bloc/reminders_event.dart';
import 'package:hisaab/app/bloc/reminders_state.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/notifications/bill_reminder.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../helpers/bloc_dispatch.dart';
import '../../helpers/fakes/fake_app_preferences_repository.dart';
import '../../helpers/fakes/fake_bill_reminders.dart';
import '../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../helpers/fakes/fake_clock.dart';
import '../../helpers/fakes/fake_ledger_repository.dart';
import '../../helpers/fakes/fake_recurring_repository.dart';
import '../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeAppPreferencesRepository preferences;
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late FakeBillReminders reminders;
  late RemindersBloc bloc;

  // Electricity changes; it went out on Sat 24 Oct and still waits. Today is Mon 26 Oct, 8:00.
  const CalendarDate oct24 = CalendarDate(2026, 10, 24);
  final RecurringRule electricity = WorkedExample.electricity.copyWith(
    amountMode: AmountMode.varies,
    schedule: const Schedule(frequency: Frequency.monthly, anchor: oct24),
    nextDue: oct24,
  );
  const BillReminderTap tapOct24 = BillReminderTap(ruleId: 3, date: oct24);

  setUp(() {
    preferences = FakeAppPreferencesRepository(done: true, reminders: const Option<bool>.of(true));
    ledger = FakeLedgerRepository(WorkedExample.entries);
    recurring = FakeRecurringRepository(<RecurringRule>[WorkedExample.salary, WorkedExample.rent, electricity]);
    reminders = FakeBillReminders();
  });

  RemindersBloc build() {
    final FakeClock clock = FakeClock(DateTime(2026, 10, 26, 8));
    final GetCycleSummary summary = GetCycleSummary(
      ledger: ledger,
      recurring: recurring,
      settings: FakeBudgetSettingsRepository(),
      periods: const PeriodCalculator(),
      clock: clock,
    );
    return bloc = RemindersBloc(
      preferences: preferences,
      arm: ArmBillReminders(recurring: recurring, summary: summary, reminders: reminders, clock: clock),
      reminders: reminders,
      getCycleSummary: summary,
      ledger: ledger,
      recurring: recurring,
    );
  }

  tearDown(() async {
    await bloc.close();
    await ledger.dispose();
    await reminders.dispose();
  });

  final Matcher openedElectricity = isA<RemindersBillOpened>()
      .having((RemindersBillOpened s) => s.bill, 'bill', Option<Occurrence>.of(Occurrence(rule: electricity, date: oct24)));

  group('RemindersBloc arming (spec §6)', () {
    test('starts idle', () => expect(build().state, const RemindersIdle()));

    test('on start, arms the next reminder of each changing bill', () async {
      await build().dispatch(const RemindersStarted());
      expect(reminders.scheduled.single.date, const CalendarDate(2026, 11, 24));
      expect(reminders.kept, <int>{BillReminder.idFor(3, oct24)});
    });

    test('never asked, or Not now: every reminder is removed', () async {
      preferences.reminders = const Option<bool>.none();
      await build().dispatch(const RemindersStarted());
      expect(reminders.arms, 1);
      expect(reminders.scheduled, isEmpty);
    });

    test('a failed read arms nothing and stays quiet', () async {
      preferences.failure = DatabaseFailure('locked');
      await build().dispatch(const RemindersArmRequested());
      expect(reminders.arms, 0);
      expect(bloc.state, const RemindersIdle());
    });

    test('a write to the ledger or the bills arms again', () async {
      build();
      await ledger.add(EntryDraft(amount: WorkedExample.rent.amount, kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today)).run();
      await pumpEventQueue();
      await recurring.update(electricity.copyWith(label: 'Power')).run();
      await pumpEventQueue();
      expect(reminders.arms, 2);
      expect(reminders.scheduled.single.billName, 'Power');
    });

    test('arms one at a time, so a slow older arm never lands last', () async {
      build();
      final Completer<void> slowRead = Completer<void>();
      recurring.nextReadGate = slowRead;
      bloc.add(const RemindersArmRequested());
      await pumpEventQueue();
      recurring.rules = <RecurringRule>[WorkedExample.salary, electricity.copyWith(label: 'Power')];
      bloc.add(const RemindersArmRequested());
      await pumpEventQueue();
      slowRead.complete();
      await pumpEventQueue();
      expect(reminders.scheduled.single.billName, 'Power');
    });
  });

  group('RemindersBloc taps (spec §6)', () {
    test('a tap that started the app opens that bill, then goes idle', () async {
      reminders.launchedBy = const Option<BillReminderTap>.of(tapOct24);
      build();
      final Future<void> expectation = expectLater(bloc.stream, emitsInOrder(<Matcher>[openedElectricity, equals(const RemindersIdle())]));
      await bloc.dispatch(const RemindersStarted());
      await expectation;
    });

    test('a tap while running opens that bill', () async {
      build();
      final Future<void> expectation = expectLater(bloc.stream, emitsThrough(openedElectricity));
      reminders.tapOn(tapOct24);
      await expectation;
    });

    test('a tap for a bill already answered opens only Home', () async {
      build();
      final Future<void> expectation =
          expectLater(bloc.stream, emitsThrough(const RemindersBillOpened(Option<Occurrence>.none())));
      await bloc.dispatch(const RemindersTapped(BillReminderTap(ruleId: 3, date: CalendarDate(2026, 9, 24))));
      await expectation;
    });

    test('a tap when the bills can\'t be read opens only Home', () async {
      build();
      ledger.failure = DatabaseFailure('locked');
      final Future<void> expectation =
          expectLater(bloc.stream, emitsThrough(const RemindersBillOpened(Option<Occurrence>.none())));
      await bloc.dispatch(const RemindersTapped(tapOct24));
      await expectation;
    });

    test('events and states compare by their fields', () {
      expect(const RemindersTapped(tapOct24).props, <Object?>[tapOct24]);
      expect(const RemindersStarted().props, isEmpty);
      expect(const RemindersArmRequested().props, isEmpty);
      expect(const RemindersIdle().props, isEmpty);
      expect(const RemindersBillOpened(Option<Occurrence>.none()).props, <Object?>[const Option<Occurrence>.none()]);
    });
  });
}
