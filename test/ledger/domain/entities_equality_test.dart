import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/ledger/domain/entities/cycle_inputs.dart';
import 'package:expense_tracker/ledger/domain/entities/occurrence.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_posting.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  group('ledger entities compare by value', () {
    test('LedgerSetup and RecurringDraft', () {
      final RecurringDraft draft = RecurringDraft(
        label: 'Rent',
        amount: Money.fromMajor(8200),
        kind: EntryKind.spent,
        categoryId: 7,
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 5)),
        nextDue: const CalendarDate(2026, 10, 5),
      );
      expect(draft.props, hasLength(8));
      expect(LedgerSetup(rules: <RecurringDraft>[draft]).props, <Object?>[<RecurringDraft>[draft], <EntryDraft>[]]);
    });

    test('Occurrence and RecurringPosting', () {
      final Occurrence occurrence = Occurrence(rule: WorkedExample.rent, date: const CalendarDate(2026, 11, 5));
      expect(occurrence.props, <Object?>[WorkedExample.rent, const CalendarDate(2026, 11, 5)]);
      final RecurringPosting posting =
          RecurringPosting(occurrences: <Occurrence>[occurrence], nextDueByRuleId: const <int, CalendarDate>{});
      expect(posting.props, hasLength(2));
      expect(posting.isEmpty, isFalse);
    });

    test('CycleInputs', () {
      final CycleInputs inputs = CycleInputs(
        cycle: const PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3)),
        today: WorkedExample.today,
        income: Money.zero,
        savingsDue: Money.zero,
        savedBefore: Money.zero,
        savedByRuleToday: Money.zero,
        savedExtraToday: Money.zero,
        billsDue: Money.zero,
        billsPostedToday: Money.zero,
        spentBefore: Money.zero,
        spentToday: Money.zero,
        paceSpentBefore: Money.zero,
        hasIncomeRule: false,
      );
      expect(inputs.props, hasLength(13));
    });

    test('forecasts without data', () {
      expect(const TooEarlyToForecast().props, isEmpty);
    });

    test('RecurringRule.copyWith keeps what isn\'t passed, and its draft drops only the id', () {
      expect(WorkedExample.rent.copyWith(), WorkedExample.rent);
      expect(WorkedExample.salary.draft.isIncomeSource, isTrue);
    });

    test('bill params compare by their fields', () {
      final BillInput input = BillInput(label: 'Rent', amount: Money.fromMajor(8200), dueDay: 5);
      expect(AddBillParams(input: input), AddBillParams(input: input));
      expect(EditBillParams(rule: WorkedExample.rent, input: input).props, <Object?>[WorkedExample.rent, input]);
    });
  });
}
