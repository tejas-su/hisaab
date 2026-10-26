import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../errors/failure.dart';

/// When the user's income arrives; decides where each pay cycle starts (SPEC BR-1).
sealed class PayRule extends Equatable {
  const PayRule();
}

/// Paid on the same day every month; days past the month's end clamp to its last day.
final class MonthlyOnDay extends PayRule {
  /// Creates a monthly rule for [day] (1–31) without validation.
  const MonthlyOnDay(this.day);

  /// Validates [day]: Right with the rule for 1–31, Left with [InvalidDataFailure] otherwise.
  static Either<Failure, PayRule> validate(int day) => day >= 1 && day <= 31
      ? Either<Failure, PayRule>.right(MonthlyOnDay(day))
      : Either<Failure, PayRule>.left(InvalidDataFailure('Pay day must be 1–31, got $day'));

  final int day;

  @override
  List<Object?> get props => <Object?>[day];
}

/// Paid on the last day of every month.
final class LastDayOfMonth extends PayRule {
  const LastDayOfMonth();

  @override
  List<Object?> get props => <Object?>[];
}

/// Paid every week on [weekday] ([DateTime.monday] … [DateTime.sunday]).
final class WeeklyOn extends PayRule {
  /// Creates a weekly rule without validation.
  const WeeklyOn(this.weekday);

  /// Validates [weekday]: Right with the rule for 1–7, Left with [InvalidDataFailure] otherwise.
  static Either<Failure, PayRule> validate(int weekday) =>
      weekday >= DateTime.monday && weekday <= DateTime.sunday
          ? Either<Failure, PayRule>.right(WeeklyOn(weekday))
          : Either<Failure, PayRule>.left(InvalidDataFailure('Weekday must be 1–7, got $weekday'));

  final int weekday;

  @override
  List<Object?> get props => <Object?>[weekday];
}

/// Income with no fixed date ("It changes"); cycles follow the calendar month.
final class IrregularIncome extends PayRule {
  const IrregularIncome();

  @override
  List<Object?> get props => <Object?>[];
}
