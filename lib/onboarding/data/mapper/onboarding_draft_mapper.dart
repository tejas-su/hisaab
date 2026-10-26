import 'dart:convert';

import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/time/pay_rule.dart';
import '../../domain/entities/bill_draft.dart';
import '../../domain/entities/bill_kind.dart';
import '../../domain/entities/onboarding_draft.dart';
import '../../domain/entities/onboarding_step.dart';

/// Converts an [OnboardingDraft] to and from the JSON text stored in `settings`.
///
/// The text carries a version so a later app can tell an old draft apart; amounts are paise.
abstract final class OnboardingDraftMapper {
  static const int _version = 1;

  /// The JSON text for [draft].
  static String toJson(OnboardingDraft draft) => jsonEncode(<String, Object?>{
        'v': _version,
        'step': draft.step.name,
        'incomeMinor': draft.income.amountMinor,
        'payRule': draft.payRule.map(_payRuleJson).toNullable(),
        'bills': draft.bills
            .map((BillDraft bill) => <String, Object?>{
                  'kind': bill.kind.name,
                  'amountMinor': bill.amount.amountMinor,
                  'dueDay': bill.dueDay,
                })
            .toList(),
      });

  /// Reads a draft from [json].
  ///
  /// Returns [Right] with the draft, or [Left] with [InvalidDataFailure] for malformed text, an
  /// unknown version, step, pay rule or bill, or an out-of-range day.
  static Either<Failure, OnboardingDraft> fromJson(String json) =>
      Either<Failure, Object?>.tryCatch(() => jsonDecode(json), (Object error, StackTrace _) => _invalid('not JSON'))
          .flatMap(_draft);

  static Either<Failure, OnboardingDraft> _draft(Object? decoded) => switch (decoded) {
        {
          'v': _version,
          'step': final String step,
          'incomeMinor': final int income,
          'payRule': final Object? payRule,
          'bills': final List<Object?> bills,
        } =>
          _byName(OnboardingStep.values, step).flatMap(
            (OnboardingStep step) => _optionalPayRule(payRule).flatMap(
              (Option<PayRule> rule) => bills.traverseEither(_bill).map(
                    (List<BillDraft> bills) =>
                        OnboardingDraft(step: step, income: Money(income), payRule: rule, bills: bills),
                  ),
            ),
          ),
        _ => Either<Failure, OnboardingDraft>.left(_invalid('unexpected shape')),
      };

  static Map<String, Object?> _payRuleJson(PayRule rule) => switch (rule) {
        MonthlyOnDay(:final int day) => <String, Object?>{'type': 'monthly', 'day': day},
        LastDayOfMonth() => <String, Object?>{'type': 'lastDay'},
        WeeklyOn(:final int weekday) => <String, Object?>{'type': 'weekly', 'weekday': weekday},
        IrregularIncome() => <String, Object?>{'type': 'irregular'},
      };

  static Either<Failure, Option<PayRule>> _optionalPayRule(Object? json) => json == null
      ? Either<Failure, Option<PayRule>>.right(const Option<PayRule>.none())
      : _payRule(json).map(Option<PayRule>.of);

  static Either<Failure, PayRule> _payRule(Object? json) => switch (json) {
        {'type': 'monthly', 'day': final int day} => MonthlyOnDay.validate(day),
        {'type': 'lastDay'} => Either<Failure, PayRule>.right(const LastDayOfMonth()),
        {'type': 'weekly', 'weekday': final int weekday} => WeeklyOn.validate(weekday),
        {'type': 'irregular'} => Either<Failure, PayRule>.right(const IrregularIncome()),
        _ => Either<Failure, PayRule>.left(_invalid('unknown pay rule')),
      };

  static Either<Failure, BillDraft> _bill(Object? json) => switch (json) {
        {'kind': final String kind, 'amountMinor': final int amount, 'dueDay': final int dueDay}
            when dueDay >= 1 && dueDay <= 31 =>
          _byName(BillKind.values, kind).map((BillKind kind) => BillDraft(kind: kind, amount: Money(amount), dueDay: dueDay)),
        _ => Either<Failure, BillDraft>.left(_invalid('bad bill')),
      };

  static Either<Failure, T> _byName<T extends Enum>(List<T> values, String name) =>
      Option<T>.fromNullable(values.where((T value) => value.name == name).firstOrNull)
          .toEither<Failure>(() => _invalid('unknown value "$name"'));

  static InvalidDataFailure _invalid(String reason) => InvalidDataFailure('Onboarding draft: $reason');
}
