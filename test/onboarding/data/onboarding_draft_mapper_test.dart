import 'dart:convert';

import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/pay_rule.dart';
import 'package:hisaab/onboarding/data/mapper/onboarding_draft_mapper.dart';
import 'package:hisaab/onboarding/domain/entities/bill_draft.dart';
import 'package:hisaab/ledger/domain/entities/bill_kind.dart';
import 'package:hisaab/onboarding/domain/entities/onboarding_draft.dart';
import 'package:hisaab/onboarding/domain/entities/onboarding_step.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('OnboardingDraftMapper', () {
    final List<OnboardingDraft> drafts = <OnboardingDraft>[
      const OnboardingDraft(),
      OnboardingDraft(step: OnboardingStep.payday, income: Money.fromMajor(45000)),
      OnboardingDraft(
        step: OnboardingStep.bills,
        income: Money.fromMajor(45000),
        payRule: const Option<PayRule>.of(MonthlyOnDay(31)),
        bills: <BillDraft>[BillDraft(kind: BillKind.schoolFees, amount: Money.fromMajor(3000), dueDay: 10)],
      ),
      const OnboardingDraft(payRule: Option<PayRule>.of(LastDayOfMonth())),
      const OnboardingDraft(payRule: Option<PayRule>.of(WeeklyOn(DateTime.saturday))),
      const OnboardingDraft(payRule: Option<PayRule>.of(IrregularIncome())),
    ];
    for (final OnboardingDraft draft in drafts) {
      test('round-trips $draft', () {
        expect(OnboardingDraftMapper.fromJson(OnboardingDraftMapper.toJson(draft)), Either<Failure, OnboardingDraft>.right(draft));
      });
    }

    Map<String, Object?> valid() => jsonDecode(OnboardingDraftMapper.toJson(const OnboardingDraft())) as Map<String, Object?>;

    final List<(String, String)> bad = <(String, String)>[
      ('text that is not JSON', 'not json'),
      ('an unknown version', jsonEncode(<String, Object?>{...valid(), 'v': 99})),
      ('an unknown step', jsonEncode(<String, Object?>{...valid(), 'step': 'done'})),
      ('an unknown pay rule', jsonEncode(<String, Object?>{...valid(), 'payRule': <String, Object?>{'type': 'daily'}})),
      ('a pay day of 32', jsonEncode(<String, Object?>{...valid(), 'payRule': <String, Object?>{'type': 'monthly', 'day': 32}})),
      ('a bill due on day 0', jsonEncode(<String, Object?>{
        ...valid(),
        'bills': <Object?>[<String, Object?>{'kind': 'rent', 'amountMinor': 100, 'dueDay': 0}],
      })),
      ('an unknown bill kind', jsonEncode(<String, Object?>{
        ...valid(),
        'bills': <Object?>[<String, Object?>{'kind': 'yacht', 'amountMinor': 100, 'dueDay': 1}],
      })),
    ];
    for (final (String name, String json) in bad) {
      test('returns InvalidDataFailure for $name', () {
        expect(OnboardingDraftMapper.fromJson(json).getLeft().toNullable(), isA<InvalidDataFailure>());
      });
    }
  });
}
