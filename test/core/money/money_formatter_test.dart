import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/money/money_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MoneyFormatter (en_IN)', () {
    final MoneyFormatter formatter = MoneyFormatter();

    test('groups thousands the Indian way', () {
      expect(formatter.format(Money.fromMajor(125000)), '₹1,25,000');
      expect(formatter.format(Money.fromMajor(12345678)), '₹1,23,45,678');
    });

    test('never shows paise', () {
      expect(formatter.format(const Money(143099)), '₹1,430');
    });

    test('formats zero', () {
      expect(formatter.format(Money.zero), '₹0');
    });

    test('formats the 9-digit maximum (SPEC E11)', () {
      expect(formatter.format(Money.fromMajor(999999999)), '₹99,99,99,999');
    });

    test('compact uses lakh and crore', () {
      expect(formatter.compact(Money.fromMajor(125000)), '₹1.25L');
      expect(formatter.compact(Money.fromMajor(12500000)), '₹1.25Cr');
      expect(formatter.compact(Money.fromMajor(20000)), '₹20K');
    });

    test('digits omits the symbol for spoken labels', () {
      expect(formatter.digits(Money.fromMajor(1430)), '1,430');
    });

    test('formats negative amounts with a leading minus', () {
      expect(formatter.format(Money.fromMajor(-1200)), '-₹1,200');
    });
  });
}
