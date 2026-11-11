import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/domain/usecase/answer_bill_reminders.dart';
import 'package:hisaab/settings/domain/usecase/should_ask_bill_reminders.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_app_preferences_repository.dart';
import '../../../helpers/fakes/fake_bill_reminders.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeAppPreferencesRepository preferences;
  late FakeRecurringRepository recurring;
  late FakeLedgerRepository ledger;
  late FakeBillReminders reminders;

  final RecurringRule changing = WorkedExample.electricity.copyWith(
    amountMode: AmountMode.varies,
    schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 29)),
  );

  setUp(() {
    preferences = FakeAppPreferencesRepository(done: true);
    recurring = FakeRecurringRepository(<RecurringRule>[WorkedExample.salary, WorkedExample.rent, changing]);
    ledger = FakeLedgerRepository(WorkedExample.entries);
    reminders = FakeBillReminders();
  });

  tearDown(() async {
    await ledger.dispose();
    await reminders.dispose();
  });

  Future<bool> shouldAsk() async =>
      (await ShouldAskBillReminders(preferences: preferences, recurring: recurring)(const NoParams()).run()).getOrElse((Failure f) => fail(f.message));

  AnswerBillReminders answer() {
    final FakeClock clock = FakeClock(DateTime(2026, 10, 26, 8));
    return AnswerBillReminders(
      preferences: preferences,
      reminders: reminders,
      arm: ArmBillReminders(
        recurring: recurring,
        summary: GetCycleSummary(ledger: ledger, recurring: recurring, settings: FakeBudgetSettingsRepository(), periods: const PeriodCalculator(), clock: clock),
        reminders: reminders,
        clock: clock,
      ),
    );
  }

  group('AnswerBillReminders (spec §5, §6, E-i)', () {
    test('Remind me saves yes, asks Android, then arms the reminders', () async {
      expect(await answer()(true).run(), Either<Failure, bool>.right(true));
      expect(preferences.reminders, const Option<bool>.of(true));
      expect(reminders.permissionAsks, 1);
      expect(reminders.scheduled.single.billName, 'Electricity');
    });

    test('Remind me with the permission refused still saves yes; nothing is asked again (E-i)', () async {
      reminders.granted = false;
      expect(await answer()(true).run(), Either<Failure, bool>.right(false));
      expect(preferences.reminders, const Option<bool>.of(true));
      expect(await shouldAsk(), isFalse);
    });

    test('Not now saves no, never asks Android, and arms nothing', () async {
      expect(await answer()(false).run(), Either<Failure, bool>.right(false));
      expect(preferences.reminders, const Option<bool>.of(false));
      expect(reminders.permissionAsks, 0);
      expect(reminders.scheduled, isEmpty);
    });

    test('a failed save asks nothing further', () async {
      preferences.failure = DatabaseFailure('locked');
      expect((await answer()(true).run()).isLeft(), isTrue);
      expect(reminders.permissionAsks, 0);
    });
  });
}
