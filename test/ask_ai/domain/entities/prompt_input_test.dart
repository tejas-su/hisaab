import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_rule.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fixtures/ask_ai/prompt_input.dart';

void main() {
  group('PromptInput.offersOnTrack (FR-AI-1)', () {
    final List<(String, PayRule, CalendarDate, bool)> cases = <(String, PayRule, CalendarDate, bool)>[
      ('the current cycle with a monthly payday', const MonthlyOnDay(4), const CalendarDate(2026, 10, 26), true),
      ('the last day of the current cycle', const MonthlyOnDay(4), const CalendarDate(2026, 11, 3), true),
      ('weekly pay', const WeeklyOn(DateTime.monday), const CalendarDate(2026, 10, 26), true),
      ('payday on the last day of the month', const LastDayOfMonth(), const CalendarDate(2026, 10, 26), true),
      ('income with no fixed payday: it lasts the month (D117)', const IrregularIncome(), const CalendarDate(2026, 10, 26), true),
      ('a past cycle (today is after it)', const MonthlyOnDay(4), const CalendarDate(2026, 11, 4), false),
    ];
    for (final (String name, PayRule rule, CalendarDate today, bool offered) in cases) {
      test('$name: $offered', () {
        expect(workedPromptInput(payRule: rule, today: today).offersOnTrack, offered);
      });
    }
  });

  group('PromptInput.endsAtMonthEnd (D117)', () {
    test("follows Home's summary of today", () {
      expect(workedPromptInput(summary: Option<CycleSummary>.of(workedSummary(endsAtMonthEnd: true))).endsAtMonthEnd, isTrue);
      expect(workedPromptInput(summary: Option<CycleSummary>.of(workedSummary())).endsAtMonthEnd, isFalse);
    });

    test('a past cycle has no summary, so no month end to name', () {
      expect(workedPromptInput().endsAtMonthEnd, isFalse);
    });
  });
}
