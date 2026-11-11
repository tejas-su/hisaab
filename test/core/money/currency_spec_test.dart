import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/currency_spec.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('CurrencySpec.fromCode', () {
    test('finds the rupee', () {
      expect(CurrencySpec.fromCode('INR'), Either<Failure, CurrencySpec>.right(CurrencySpec.inr));
    });

    test('rejects an unknown or lower-case code', () {
      expect(CurrencySpec.fromCode('USD').getLeft().toNullable(), isA<InvalidDataFailure>());
      expect(CurrencySpec.fromCode('inr').isLeft(), isTrue);
      expect(CurrencySpec.fromCode('').isLeft(), isTrue);
    });
  });
}
