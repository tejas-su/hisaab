import 'dart:convert';

import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_rule.dart';
import '../../../core/time/pay_switch.dart';

/// Converts the pay switches to and from the JSON text stored under the `pay_switches` settings
/// key (DECISIONS D140): a list of `{"on": "YYYY-MM-DD", "rule": "monthly", "day": 4}`, where
/// `rule` is `monthly` (with `day`), `last_day`, `weekly` (with `weekday`, 1–7) or `irregular`.
abstract final class PaySwitchMapper {
  static const String _on = 'on';
  static const String _rule = 'rule';
  static const String _day = 'day';
  static const String _weekday = 'weekday';
  static const String _monthly = 'monthly';
  static const String _lastDay = 'last_day';
  static const String _weekly = 'weekly';
  static const String _irregular = 'irregular';

  /// [switches] as stored text.
  static String toText(List<PaySwitch> switches) => jsonEncode(switches.map(_toJson).toList());

  /// The switches in [text]; none when [text] is null (never changed).
  ///
  /// Returns [Right] with the switches, oldest first, or [Left] with [InvalidDataFailure] for
  /// text that isn't a valid list of switches.
  static Either<Failure, List<PaySwitch>> fromText(String? text) {
    if (text == null) {
      return Either<Failure, List<PaySwitch>>.right(const <PaySwitch>[]);
    }
    return Either<Failure, Object?>.tryCatch(() => jsonDecode(text), (Object _, StackTrace _) => _invalid(text)).flatMap(
          (Object? decoded) => decoded is List<Object?>
              ? decoded.map(_fromJson).toList().sequenceEither().map((Iterable<PaySwitch> all) => all.toList())
              : Either<Failure, List<PaySwitch>>.left(_invalid(text)),
        );
  }

  static Map<String, Object?> _toJson(PaySwitch change) => <String, Object?>{
        _on: change.on.toIso(),
        ...switch (change.from) {
          MonthlyOnDay(:final int day) => <String, Object?>{_rule: _monthly, _day: day},
          LastDayOfMonth() => <String, Object?>{_rule: _lastDay},
          WeeklyOn(:final int weekday) => <String, Object?>{_rule: _weekly, _weekday: weekday},
          IrregularIncome() => <String, Object?>{_rule: _irregular},
        },
      };

  static Either<Failure, PaySwitch> _fromJson(Object? json) {
    if (json is! Map<String, Object?> || json[_on] is! String) {
      return Either<Failure, PaySwitch>.left(InvalidDataFailure('Bad pay switch $json'));
    }
    return CalendarDate.parse(json[_on]! as String)
        .flatMap((CalendarDate on) => _ruleOf(json).map((PayRule from) => PaySwitch(on: on, from: from)));
  }

  static Either<Failure, PayRule> _ruleOf(Map<String, Object?> json) => switch ((json[_rule], json[_day], json[_weekday])) {
        (_monthly, final int day, _) => MonthlyOnDay.validate(day),
        (_lastDay, _, _) => Either<Failure, PayRule>.right(const LastDayOfMonth()),
        (_weekly, _, final int weekday) => WeeklyOn.validate(weekday),
        (_irregular, _, _) => Either<Failure, PayRule>.right(const IrregularIncome()),
        _ => Either<Failure, PayRule>.left(InvalidDataFailure('Bad pay rule $json')),
      };

  static Failure _invalid(String text) => InvalidDataFailure('Bad pay switches "$text"');
}
