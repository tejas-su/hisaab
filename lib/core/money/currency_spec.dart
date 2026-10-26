import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../errors/failure.dart';

/// A currency the app can store and display: ISO code, symbol and minor-unit digits.
final class CurrencySpec extends Equatable {
  /// Creates a currency description; [minorDigits] is 2 for paise, 0 for yen.
  const CurrencySpec({required this.code, required this.symbol, required this.minorDigits});

  /// The Indian rupee, the only currency shipped in v1.
  static const CurrencySpec inr = CurrencySpec(code: 'INR', symbol: '₹', minorDigits: 2);

  /// Every currency the app knows, by ISO code.
  static const Map<String, CurrencySpec> _byCode = <String, CurrencySpec>{'INR': inr};

  /// Looks up a stored ISO [code].
  ///
  /// Returns [Right] with the currency, or [Left] with [InvalidDataFailure] for an unknown code.
  static Either<Failure, CurrencySpec> fromCode(String code) => Option<CurrencySpec>.fromNullable(_byCode[code])
      .toEither<Failure>(() => InvalidDataFailure('Unknown currency "$code"'));

  /// ISO 4217 code, stored next to every amount in the database.
  final String code;

  /// Symbol shown before formatted amounts.
  final String symbol;

  /// Number of decimal digits in the minor unit.
  final int minorDigits;

  /// How many minor units make one major unit (100 paise per rupee).
  int get minorPerMajor => List<int>.filled(minorDigits, 10).fold(1, (int a, int b) => a * b);

  @override
  List<Object?> get props => <Object?>[code, symbol, minorDigits];
}
