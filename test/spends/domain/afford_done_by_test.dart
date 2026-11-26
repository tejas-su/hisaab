import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/afford_done_by.dart';
import 'package:hisaab/spends/domain/entities/afford_answer.dart';
import 'package:hisaab/spends/domain/entities/afford_context.dart';

import '../../helpers/fixtures/spends/afford_book.dart';

const CalendarDate _today = CalendarDate(2026, 10, 26);
const PayCycle _next = PayCycle(start: CalendarDate(2026, 11, 4), end: CalendarDate(2026, 12, 3));

AffordAnswer _answer({AffordVerdict verdict = AffordVerdict.saveUp, int need = 67000, int spare = 5000}) => AffordAnswer(
      verdict: verdict,
      need: Money.fromMajor(need),
      floor: Money.fromMajor(900),
      spare: Money.fromMajor(spare),
      normalPerDay: Money.fromMajor(1066),
      cardPerDay: const None(),
      savingPerDay: const None(),
      putIns: const None(),
    );

AffordContext _context({Option<RecurringRule> existing = const Option<RecurringRule>.none(), PayCycle next = _next}) => AffordContext(
      room: Money.fromMajor(32000),
      days: 30,
      usual: Option<Money>.of(Money.fromMajor(750)),
      nextCycle: next,
      existingSaving: existing,
      existingSetAside: Money.zero,
    );

void main() {
  group('AffordDoneBy.of (BR-24 Done by)', () {
    test('a new saving: 14 put-ins from 5 Nov 2026 end on 5 Dec 2027', () {
      expect(AffordDoneBy.of(_answer(), _context(), _today), const Option<CalendarDate>.of(CalendarDate(2027, 12, 5)));
    });

    test('a next cycle starting on the 31st puts in on the 1st', () {
      const PayCycle endOfMonth = PayCycle(start: CalendarDate(2026, 10, 31), end: CalendarDate(2026, 11, 29));

      expect(
        AffordDoneBy.of(_answer(need: 5000), _context(next: endOfMonth), _today),
        const Option<CalendarDate>.of(CalendarDate(2026, 11, 1)),
      );
    });

    test('a re-checked saving keeps its own day and next date', () {
      final RecurringRule mac = AffordBook.mac().copyWith(
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 11, 20)),
        nextDue: const CalendarDate(2026, 11, 20),
      );

      expect(
        AffordDoneBy.of(_answer(need: 10000), _context(existing: Option<RecurringRule>.of(mac)), _today),
        const Option<CalendarDate>.of(CalendarDate(2026, 12, 20)),
      );
    });

    test('a re-checked saving with a next date in the past starts from its first date after today', () {
      final RecurringRule stale = AffordBook.mac().copyWith(nextDue: const CalendarDate(2026, 9, 5));

      expect(
        AffordDoneBy.of(_answer(need: 5000), _context(existing: Option<RecurringRule>.of(stale)), _today),
        const Option<CalendarDate>.of(CalendarDate(2026, 11, 5)),
      );
    });

    test('more than 120 put-ins gives no date (far)', () {
      expect(AffordDoneBy.of(_answer(need: 605000, spare: 5000), _context(), _today), const Option<CalendarDate>.none());
    });

    test('exactly 120 put-ins still gives a date', () {
      expect(AffordDoneBy.of(_answer(need: 600000, spare: 5000), _context(), _today).isSome(), isTrue);
    });

    test('Yes, without a loan gets a date for its Save up row', () {
      expect(
        AffordDoneBy.of(_answer(verdict: AffordVerdict.withCard, need: 5000), _context(), _today),
        const Option<CalendarDate>.of(CalendarDate(2026, 11, 5)),
      );
    });

    test('nothing to save for (need = 0) has no date', () {
      expect(AffordDoneBy.of(_answer(verdict: AffordVerdict.fromSavings, need: 0), _context(), _today), const Option<CalendarDate>.none());
    });

    test('nothing spare (days full or no history) has no date', () {
      expect(AffordDoneBy.of(_answer(verdict: AffordVerdict.daysFull, spare: 0), _context(), _today), const Option<CalendarDate>.none());
    });
  });
}
