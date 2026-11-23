import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import 'amount_mode.dart';
import 'bill_icon.dart';
import 'entry_kind.dart';
import 'schedule.dart';

/// A recurring rule about to be created, before it has an id (onboarding, Settings).
final class RecurringDraft extends Equatable {
  const RecurringDraft({
    required this.label,
    required this.amount,
    required this.kind,
    required this.categoryId,
    required this.schedule,
    required this.nextDue,
    this.isIncomeSource = false,
    this.icon = const Option<BillIcon>.none(),
    this.amountMode = AmountMode.fixed,
    this.target = const Option<Money>.none(),
    this.targetReachedFor = const Option<Money>.none(),
    this.targetReachedOn = const Option<CalendarDate>.none(),
  });

  final String label;
  final Money amount;
  final EntryKind kind;
  final int categoryId;
  final Schedule schedule;

  /// The first date the engine should post.
  final CalendarDate nextDue;
  final bool isIncomeSource;

  /// The bill icon the user picked; none follows the name (D118).
  final Option<BillIcon> icon;

  /// Whether the amount is fixed, changes, or is a card bill (D123).
  final AmountMode amountMode;

  /// The amount this saving aims to reach; none means no target (SPEC BR-23).
  final Option<Money> target;

  /// The target the user was last told was reached, so it is announced once (SPEC BR-23).
  final Option<Money> targetReachedFor;

  /// The day [targetReachedFor] was reached (SPEC BR-23).
  final Option<CalendarDate> targetReachedOn;

  @override
  List<Object?> get props => <Object?>[label, amount, kind, categoryId, schedule, nextDue, isIncomeSource, icon, amountMode, target, targetReachedFor, targetReachedOn];
}
