import 'package:hisaab/core/money/currency_spec.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Money', () {
    test('fromMajor stores rupees as paise', () {
      expect(Money.fromMajor(1850).amountMinor, 185000);
    });

    test('floorMajor drops paise for display', () {
      expect(const Money(143050).floorMajor, 1430);
    });

    test('floorMajor rounds negative amounts down, not toward zero', () {
      expect(const Money(-150).floorMajor, -2);
    });

    test('adds and subtracts in minor units', () {
      final Money total = Money.fromMajor(420) + Money.fromMajor(2450);
      expect(total, Money.fromMajor(2870));
      expect(total - Money.fromMajor(870), Money.fromMajor(2000));
    });

    test('multiplies by a whole count in minor units', () {
      expect(Money.fromMajor(1850) * 7, Money.fromMajor(12950));
      expect(Money.fromMajor(1850) * 0, Money.zero);
      expect(const Money(-5) * 3, const Money(-15));
    });

    test('keeps the currency when multiplying', () {
      const CurrencySpec yen = CurrencySpec(code: 'JPY', symbol: '¥', minorDigits: 0);
      expect((const Money(3, currency: yen) * 2).currency, yen);
    });

    test('compares by amount', () {
      expect(Money.fromMajor(1) < Money.fromMajor(2), isTrue);
      expect(Money.fromMajor(2) > Money.fromMajor(1), isTrue);
      expect(Money.fromMajor(2).compareTo(Money.fromMajor(2)), 0);
    });

    test('reports zero and negative', () {
      expect(Money.zero.isZero, isTrue);
      expect(const Money(-1).isNegative, isTrue);
      expect(const Money(1).isNegative, isFalse);
    });

    test('rejects arithmetic across currencies', () {
      const CurrencySpec usd = CurrencySpec(code: 'USD', symbol: r'$', minorDigits: 2);
      expect(() => Money.fromMajor(1) + Money.fromMajor(1, currency: usd), throwsArgumentError);
    });

    test('equal amounts in the same currency are equal', () {
      expect(Money.fromMajor(5), Money.fromMajor(5));
    });
  });

  group('CurrencySpec', () {
    test('INR has 100 paise per rupee', () {
      expect(CurrencySpec.inr.minorPerMajor, 100);
    });

    test('a zero-decimal currency has 1 minor unit per major unit', () {
      const CurrencySpec jpy = CurrencySpec(code: 'JPY', symbol: '¥', minorDigits: 0);
      expect(jpy.minorPerMajor, 1);
    });
  });
}
