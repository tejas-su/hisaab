import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';

/// How a cycle's money in splits: bills, saving, everyday spending, *Not logged* fixes and what
/// is left (SPEC BR-21, using BR-20's symbols). Computed when it is shown, never stored.
final class MoneySplit extends Equatable {
  const MoneySplit({required this.income, required this.bills, required this.saved, required this.everyday, required this.notLogged});

  /// Nothing in, nothing out.
  static const MoneySplit empty = MoneySplit(income: Money.zero, bills: Money.zero, saved: Money.zero, everyday: Money.zero, notLogged: Money.zero);

  /// `I`: every *Got*.
  final Money income;

  /// `B`: *Spent* posted by a rule, not *Not logged*.
  final Money bills;

  /// `Sv`: every *Saved*.
  final Money saved;

  /// `E`: *Spent* the user typed, not *Not logged*.
  final Money everyday;

  /// `NL`: *Spent* *Not logged* fixes.
  final Money notLogged;

  /// `L = I − B − E − NL − Sv`: negative past what came in.
  Money get left => income - bills - everyday - notLogged - saved;

  /// Whether anything came in, so there is a bar to split.
  bool get hasIncome => income > Money.zero;

  @override
  List<Object?> get props => <Object?>[income, bills, saved, everyday, notLogged];
}
