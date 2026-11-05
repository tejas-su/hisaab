import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/notifications/bill_reminder.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_bill_reminders.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late FakeBillReminders reminders;
  late ArmBillReminders arm;

  // Due today, Mon 26 Oct, and still waiting; the clock reads 8:00.
  final RecurringRule electricity = WorkedExample.electricity.copyWith(
    amountMode: AmountMode.varies,
    schedule: const Schedule(frequency: Frequency.monthly, anchor: WorkedExample.today),
    nextDue: WorkedExample.today,
  );

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    recurring = FakeRecurringRepository(<RecurringRule>[WorkedExample.salary, WorkedExample.rent, electricity]);
    reminders = FakeBillReminders();
    final FakeClock clock = FakeClock(DateTime(2026, 10, 26, 8));
    arm = ArmBillReminders(
      recurring: recurring,
      summary: GetCycleSummary(
        ledger: ledger,
        recurring: recurring,
        settings: FakeBudgetSettingsRepository(),
        periods: const PeriodCalculator(),
        clock: clock,
      ),
      reminders: reminders,
      clock: clock,
    );
  });

  tearDown(() async {
    await ledger.dispose();
    await reminders.dispose();
  });

  final int todaysId = BillReminder.idFor(3, WorkedExample.today);

  group('ArmBillReminders (spec §6)', () {
    test('arms each changing bill\'s next reminder and keeps the waiting ones', () async {
      expect(await arm(true).run(), Either<Failure, Unit>.right(unit));
      expect(reminders.scheduled.single.id, todaysId);
      expect(reminders.kept, <int>{todaysId});
    });

    test('once entered, today\'s reminder is neither armed nor kept', () async {
      ledger.entries.add(WorkedExample.entries[1].copyWithRule(3, WorkedExample.today));
      await arm(true).run();
      expect(reminders.scheduled.single.date, const CalendarDate(2026, 11, 26));
      expect(reminders.kept, isEmpty);
    });

    test('with reminders off, every reminder is removed', () async {
      await arm(false).run();
      expect(reminders.arms, 1);
      expect(reminders.scheduled, isEmpty);
      expect(reminders.kept, isEmpty);
    });

    test('when the waiting bills can\'t be worked out, it still arms the next ones, keeping none', () async {
      ledger.failure = DatabaseFailure('locked');
      expect((await arm(true).run()).isRight(), isTrue);
      expect(reminders.scheduled.single.date, const CalendarDate(2026, 11, 26));
      expect(reminders.kept, isEmpty);
    });

    test('returns the failure, arming nothing, when the bills can\'t be read', () async {
      recurring.failure = DatabaseFailure('locked');
      expect((await arm(true).run()).getLeft().toNullable(), isA<DatabaseFailure>());
      expect(reminders.arms, 0);
    });
  });
}

extension on Entry {
  Entry copyWithRule(int recurringId, CalendarDate on) => Entry(
        id: 99,
        amount: amount,
        kind: kind,
        categoryId: categoryId,
        date: on,
        createdAt: createdAt,
        recurringId: recurringId,
      );
}
