import 'package:equatable/equatable.dart';

import 'currency_spec.dart';

/// An exact amount of money held as integer minor units (paise), never as a double.
final class Money extends Equatable implements Comparable<Money> {
  /// Creates an amount of [amountMinor] minor units in [currency].
  const Money(this.amountMinor, {this.currency = CurrencySpec.inr});

  /// Creates an amount from whole major units, e.g. rupees typed on the keypad.
  factory Money.fromMajor(int major, {CurrencySpec currency = CurrencySpec.inr}) =>
      Money(major * currency.minorPerMajor, currency: currency);

  /// Zero rupees.
  static const Money zero = Money(0);

  /// The amount in minor units (paise for INR).
  final int amountMinor;

  /// The currency of this amount.
  final CurrencySpec currency;

  /// Whole major units, rounded down (SPEC §3: display rounding floors to the rupee).
  int get floorMajor => (amountMinor / currency.minorPerMajor).floor();

  bool get isZero => amountMinor == 0;

  bool get isNegative => amountMinor < 0;

  /// Returns the sum of this and [other]; both must share a currency.
  Money operator +(Money other) => Money(amountMinor + _sameCurrency(other).amountMinor, currency: currency);

  /// Returns this minus [other]; both must share a currency.
  Money operator -(Money other) => Money(amountMinor - _sameCurrency(other).amountMinor, currency: currency);

  bool operator <(Money other) => compareTo(other) < 0;

  bool operator >(Money other) => compareTo(other) > 0;

  @override
  int compareTo(Money other) => amountMinor.compareTo(_sameCurrency(other).amountMinor);

  Money _sameCurrency(Money other) {
    if (other.currency != currency) {
      throw ArgumentError('Cannot combine ${currency.code} with ${other.currency.code}');
    }
    return other;
  }

  @override
  List<Object?> get props => <Object?>[amountMinor, currency];
}
