import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

BillInput _input({String label = 'Electricity', int rupees = 1200, int day = 29}) =>
    BillInput(label: label, amount: Money.fromMajor(rupees), dueDay: day);

void main() {
  group('BillValidator (FR-SE-1)', () {
    test('accepts a typical bill', () {
      expect(BillValidator.validate(_input()), Either<Failure, BillInput>.right(_input()));
    });

    test('trims the name', () {
      expect(BillValidator.validate(_input(label: '  Rent  ')), Either<Failure, BillInput>.right(_input(label: 'Rent')));
    });

    test('accepts a name of exactly the maximum length', () {
      final String name = 'a' * BillValidator.maxLabelLength;
      expect(BillValidator.validate(_input(label: name)).isRight(), isTrue);
    });

    test('accepts unicode names', () {
      expect(BillValidator.validate(_input(label: 'बिजली')).isRight(), isTrue);
    });

    for (final (String name, String label) in <(String, String)>[
      ('an empty name', ''),
      ('a blank name', '   '),
      ('a name one past the maximum', 'a' * (BillValidator.maxLabelLength + 1)),
    ]) {
      test('rejects $name with InvalidBillNameFailure', () {
        expect(BillValidator.validate(_input(label: label)).getLeft().toNullable(), isA<InvalidBillNameFailure>());
      });
    }

    for (final (String name, Money amount) in <(String, Money)>[
      ('₹0', Money.zero),
      ('less than ₹1', const Money(99)),
      ('more than 9 digits', Money.fromMajor(1000000000)),
    ]) {
      test('rejects $name with InvalidAmountFailure', () {
        final BillInput input = BillInput(label: 'Rent', amount: amount, dueDay: 1);
        expect(BillValidator.validate(input).getLeft().toNullable(), isA<InvalidAmountFailure>());
      });
    }

    test('accepts the 9-digit cap', () {
      expect(BillValidator.validate(_input(rupees: 999999999)).isRight(), isTrue);
    });

    for (final int day in <int>[0, 32, -1]) {
      test('rejects due day $day with InvalidDataFailure', () {
        expect(BillValidator.validate(_input(day: day)).getLeft().toNullable(), isA<InvalidDataFailure>());
      });
    }

    for (final int day in <int>[1, 31]) {
      test('accepts due day $day', () {
        expect(BillValidator.validate(_input(day: day)).isRight(), isTrue);
      });
    }
  });
}
