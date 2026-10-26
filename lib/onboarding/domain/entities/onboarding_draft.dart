import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../core/time/pay_rule.dart';
import 'bill_draft.dart';
import '../../../ledger/ledger.dart';
import 'onboarding_step.dart';

/// The answers so far, saved after every change so onboarding resumes where it stopped (FR-ON-6).
final class OnboardingDraft extends Equatable {
  const OnboardingDraft({
    this.step = OnboardingStep.income,
    this.income = Money.zero,
    this.payRule = const Option<PayRule>.none(),
    this.bills = const <BillDraft>[],
  });

  final OnboardingStep step;

  /// Money that comes in each month.
  final Money income;

  /// When it comes; [None] until step 2 is answered.
  final Option<PayRule> payRule;

  /// At most one bill per [BillKind], in the order they were added.
  final List<BillDraft> bills;

  /// Returns a copy with the given fields replaced.
  OnboardingDraft copyWith({OnboardingStep? step, Money? income, Option<PayRule>? payRule, List<BillDraft>? bills}) =>
      OnboardingDraft(
        step: step ?? this.step,
        income: income ?? this.income,
        payRule: payRule ?? this.payRule,
        bills: bills ?? this.bills,
      );

  /// Returns a copy with [bill] added, replacing any bill of the same kind.
  OnboardingDraft withBill(BillDraft bill) =>
      copyWith(bills: <BillDraft>[...withoutBill(bill.kind).bills, bill]);

  /// Returns a copy without the bill of [kind].
  OnboardingDraft withoutBill(BillKind kind) =>
      copyWith(bills: bills.where((BillDraft bill) => bill.kind != kind).toList());

  @override
  List<Object?> get props => <Object?>[step, income, payRule, bills];
}
