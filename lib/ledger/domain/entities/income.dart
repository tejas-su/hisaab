import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import 'entry.dart';
import 'recurring_rule.dart';

/// The money coming in, as Settings shows it (SPEC FR-SE-1): the salary rule, if the income has
/// a fixed day, and the pay that rule posted last.
final class Income extends Equatable {
  const Income({required this.rule, this.latestPay = const Option<Entry>.none(), this.receivedThisMonth = Money.zero});

  /// None for "It changes", which has no rule (D27).
  final Option<RecurringRule> rule;

  /// The rule's most recent posted pay; none before the first payday or when it was deleted.
  final Option<Entry> latestPay;

  /// Every *Got* this calendar month, to prefill the amount when "It changes" gets a fixed day;
  /// zero when there is a rule.
  final Money receivedThisMonth;

  @override
  List<Object?> get props => <Object?>[rule, latestPay, receivedThisMonth];
}
