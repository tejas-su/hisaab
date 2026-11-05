import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/usecases/use_case.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/settings/domain/usecase/should_ask_bill_reminders.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_app_preferences_repository.dart';
import '../../../helpers/fakes/fake_bill_reminders.dart';
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

  group('ShouldAskBillReminders (spec §5)', () {
    test('asks once a changing bill exists and it was never asked', () async => expect(await shouldAsk(), isTrue));

    test('a card bill asks too', () async {
      recurring.rules = <RecurringRule>[WorkedExample.salary, changing.copyWith(amountMode: AmountMode.card)];
      expect(await shouldAsk(), isTrue);
    });

    test('only fixed bills: no ask', () async {
      recurring.rules = WorkedExample.rules;
      expect(await shouldAsk(), isFalse);
    });

    test('answered before, either way: never asked again', () async {
      preferences.reminders = const Option<bool>.of(false);
      expect(await shouldAsk(), isFalse);
      preferences.reminders = const Option<bool>.of(true);
      expect(await shouldAsk(), isFalse);
    });

    test('returns the failure when the answer can\'t be read', () async {
      preferences.failure = DatabaseFailure('locked');
      expect((await ShouldAskBillReminders(preferences: preferences, recurring: recurring)(const NoParams()).run()).isLeft(), isTrue);
    });
  });
}
