import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/ask_ai/domain/entities/prompt_choice.dart';
import 'package:hisaab/ask_ai/domain/entities/prompt_text.dart';
import 'package:hisaab/ask_ai/domain/prompt_builder.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/ledger/ledger.dart';

import '../../helpers/fixtures/ask_ai/prompt_input.dart';
import '../../helpers/fixtures/ledger/worked_example.dart';

const String _targetClause =
    'A saving with a target is something the user chose to save up to. The date is an estimate at the current monthly amount, '
    'and a saving with a target stops putting in when it reaches the target. Treat the target as a goal, not as spending.';

const String _base =
    'You are a friendly money coach for someone in India. Reply in simple English, under 200 words.\n'
    'Use only the numbers below. Write amounts in ₹ with Indian grouping (₹1,25,000).\n'
    "If there is too little data to judge, say so. Don't name specific stocks, funds, loans or apps.\n"
    'Context: income ₹45,000/month (payday 4th), currency INR, period 2026-10-04..2026-11-03, today 2026-10-26.\n';

RecurringRule _rd({Option<Money> target = const Option<Money>.none(), Money? amount}) => RecurringRule(
  id: WorkedExample.rd.id,
  label: WorkedExample.rd.label,
  amount: amount ?? WorkedExample.rd.amount,
  kind: EntryKind.saved,
  categoryId: WorkedExample.rd.categoryId,
  schedule: WorkedExample.rd.schedule,
  nextDue: WorkedExample.rd.nextDue,
  target: target,
);

RecurringRule _insurance(Money target) => RecurringRule(
  id: WorkedExample.insurance.id,
  label: WorkedExample.insurance.label,
  amount: WorkedExample.insurance.amount,
  kind: EntryKind.saved,
  categoryId: WorkedExample.insurance.categoryId,
  schedule: WorkedExample.insurance.schedule,
  nextDue: WorkedExample.insurance.nextDue,
  target: Option<Money>.of(target),
);

PromptText _build(List<RecurringRule> savings, Map<int, Money> setAside) => PromptBuilder.build(
  workedPromptInput(
    summary: Option<CycleSummary>.of(workedSummary()),
    savings: savings,
    setAsideBySaving: setAside,
  ),
  const PromptChoice(),
  nameOf: englishName,
);

String _facts(PromptText prompt) => prompt.text.split('\n')[4];

/// The saving target in the export (SPEC BR-15, BR-23, D215).
void main() {
  final RecurringRule rd = _rd(target: Option<Money>.of(Money.fromMajor(50000)));
  final RecurringRule insurance = _insurance(Money.fromMajor(12000));

  group('PromptBuilder with a saving target (BR-15, D215)', () {
    test('golden: an estimate, a reached one and the explaining line', () {
      final PromptText prompt = _build(<RecurringRule>[rd, insurance], <int, Money>{
        rd.id: Money.fromMajor(18000),
        insurance.id: Money.fromMajor(12000),
      });

      expect(
        prompt.text.split('\nSpent ').first,
        '$_base'
        'From my app, and correct: safe to spend today ₹1,430; at this pace it lasts till payday with about ₹9,300 spare; '
        'I save ₹5,000 a month (RD on the 10th).\n'
        'My Insurance saving has reached its target of ₹12,000, with ₹12,000 set aside. It puts in nothing more. '
        'My RD saving has a target of ₹50,000 and ₹18,000 set aside. '
        'At ₹5,000 a month it would reach the target around 2027-05-10.\n'
        '$_targetClause',
      );
    });

    test('an estimate with nothing set aside says so', () {
      expect(
        _build(<RecurringRule>[rd], const <int, Money>{}).text,
        contains(
          'My RD saving has a target of ₹50,000 and nothing set aside yet. '
          'At ₹5,000 a month it would reach the target around 2027-08-10.',
        ),
      );
    });

    test('a far target promises no date', () {
      final RecurringRule slow = _rd(target: Option<Money>.of(Money.fromMajor(50000)), amount: Money.fromMajor(300));
      expect(
        _build(<RecurringRule>[slow], <int, Money>{slow.id: Money.fromMajor(500)}).text,
        contains(
          'My RD saving has a target of ₹50,000 and ₹500 set aside. '
          'At ₹300 a month it is more than 10 years from the target.',
        ),
      );
    });

    test('reached savings are left out of the monthly total', () {
      final String facts = _facts(
        _build(<RecurringRule>[rd, insurance], <int, Money>{insurance.id: Money.fromMajor(12000)}),
      );
      expect(facts, endsWith('I save ₹5,000 a month (RD on the 10th).'));
    });

    test('when every saving has reached its target the savings clause is left out', () {
      final String facts = _facts(
        _build(<RecurringRule>[insurance], <int, Money>{insurance.id: Money.fromMajor(12000)}),
      );
      expect(facts, 'From my app, and correct: safe to spend today ₹1,430; at this pace it lasts till payday with about ₹9,300 spare.');
    });

    test('savings without a target add nothing, so the export is unchanged', () {
      final PromptText prompt = _build(<RecurringRule>[_rd()], <int, Money>{WorkedExample.rd.id: Money.fromMajor(18000)});
      expect(prompt.text, isNot(contains('target')));
    });

    test('no facts line without income, so no target sentences either', () {
      final PromptText prompt = PromptBuilder.build(
        workedPromptInput(savings: <RecurringRule>[rd], setAsideBySaving: <int, Money>{rd.id: Money.zero}),
        const PromptChoice(),
        nameOf: englishName,
      );
      expect(prompt.text, isNot(contains('target')));
    });
  });
}
