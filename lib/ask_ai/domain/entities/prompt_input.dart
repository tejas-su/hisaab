import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_cycle.dart';
import '../../../core/time/pay_rule.dart';
import '../../../ledger/ledger.dart';

/// The ledger data a prompt is built from, loaded once for the longest period (SPEC BR-15).
final class PromptInput extends Equatable {
  const PromptInput({
    required this.cycles,
    required this.today,
    required this.incomeRule,
    required this.payRule,
    required this.bills,
    required this.categories,
    required this.entries,
  });

  /// The cycle Spends was showing, then the two before it: always 3, newest first.
  final List<PayCycle> cycles;

  final CalendarDate today;

  /// The salary rule; [None] when income has no rule.
  final Option<RecurringRule> incomeRule;

  final PayRule payRule;

  /// Active *Spent* rules, such as rent.
  final List<RecurringRule> bills;

  final List<Category> categories;

  /// Entries from the oldest cycle's start to the newest cycle's end or today, in any order.
  final List<Entry> entries;

  @override
  List<Object?> get props => <Object?>[cycles, today, incomeRule, payRule, bills, categories, entries];
}
