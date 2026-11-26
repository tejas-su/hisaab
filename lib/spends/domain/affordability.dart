import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/money/money.dart';
import 'entities/afford_answer.dart';

/// What *Can I afford it?* reads once when it opens (SPEC BR-24).
final class AffordInputs extends Equatable {
  const AffordInputs({
    required this.price,
    required this.have,
    required this.room,
    required this.days,
    required this.usual,
  });

  final Money price;

  /// Money already put away for it, outside the app.
  final Money have;

  /// The next cycle's money after bills and savings.
  final Money room;

  /// The next cycle's length in days, at least 1.
  final int days;

  /// Average spent a day over the last fully tracked cycle; [None] when there is no history.
  final Option<Money> usual;

  @override
  List<Object?> get props => <Object?>[price, have, room, days, usual];
}

/// The *Can I afford it?* rule, in paise only (SPEC BR-24).
abstract final class Affordability {
  /// Gives the verdict and the day amounts for [inputs]. Pure: the same inputs give the same answer.
  static AffordAnswer answer(AffordInputs inputs) {
    final int room = inputs.room.amountMinor;
    final int days = inputs.days;
    final int need = _max0(inputs.price.amountMinor - inputs.have.amountMinor);
    final int normal = _perDayRupees(room, days);

    final int? usual = inputs.usual.toNullable()?.amountMinor;
    if (usual == null) {
      return AffordAnswer(
        verdict: need == 0 ? AffordVerdict.fromSavings : AffordVerdict.tooEarly,
        need: Money(need),
        floor: Money.zero,
        spare: Money.zero,
        normalPerDay: Money(normal),
        cardPerDay: const None(),
        savingPerDay: const None(),
        putIns: const None(),
      );
    }

    final int floor = _ceilTo(usual * 12, _rupees(100)) ~/ 10;
    final int spare = _max0(_floorTo(room - floor * days, _rupees(500)));

    final AffordVerdict verdict = need == 0
        ? AffordVerdict.fromSavings
        : need <= spare
        ? AffordVerdict.withCard
        : spare > 0
        ? AffordVerdict.saveUp
        : AffordVerdict.daysFull;

    return AffordAnswer(
      verdict: verdict,
      need: Money(need),
      floor: Money(floor),
      spare: Money(spare),
      normalPerDay: Money(normal),
      cardPerDay: need > 0
          ? Some<Money>(Money(_perDayRupees(room - need, days)))
          : const None(),
      savingPerDay: spare > 0
          ? Some<Money>(Money(_perDayRupees(room - spare, days)))
          : const None(),
      putIns: verdict == AffordVerdict.saveUp
          ? Some<int>((need + spare - 1) ~/ spare)
          : const None(),
    );
  }

  static int _rupees(int rupees) => rupees * 100;

  static int _max0(int paise) => paise < 0 ? 0 : paise;

  static int _floorTo(int paise, int step) =>
      paise < 0 ? -((-paise + step - 1) ~/ step) * step : paise ~/ step * step;

  static int _ceilTo(int paise, int step) => (paise + step - 1) ~/ step * step;

  /// A day's share floored to the rupee; never below zero (a path that overspends reads as ₹0).
  static int _perDayRupees(int paise, int days) =>
      _max0(paise) ~/ days ~/ 100 * 100;
}
