import 'package:expense_tracker/ledger/domain/entities/bill_icon.dart';
import 'package:expense_tracker/ledger/domain/entities/bill_kind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('BillIcon.forName (SPEC BR-9, D118)', () {
    test('picks the first matching group, top to bottom', () {
      expect(BillIcon.forName('Electricity'), BillIcon.power);
      expect(BillIcon.forName('Car EMI'), BillIcon.loan); // loan before car
      expect(BillIcon.forName('Airtel fibre'), BillIcon.internet); // internet before phone
      expect(BillIcon.forName('light bill'), BillIcon.power); // two-word key
      expect(BillIcon.forName('  RENT '), BillIcon.home);
      expect(BillIcon.forName('Gas cylinder'), BillIcon.gas);
      expect(BillIcon.forName('Bai'), BillIcon.help);
      expect(BillIcon.forName('Wi-Fi'), BillIcon.internet); // hyphen kept inside a word
    });

    test('matches whole words only', () {
      expect(BillIcon.forName('Vitamins'), BillIcon.bill); // "vi" is a word key, not a prefix
      expect(BillIcon.forName('Actor class'), BillIcon.school);
    });

    test('falls back to bill', () {
      expect(BillIcon.forName('Gym'), BillIcon.bill);
      expect(BillIcon.forName(''), BillIcon.bill);
    });

    test('lists the 16 icons in grid order', () {
      expect(BillIcon.values.map((BillIcon icon) => icon.value), <String>[
        'bill', 'home', 'power', 'phone', 'internet', 'loan', 'card', 'tv', //
        'school', 'water', 'gas', 'insurance', 'help', 'milk', 'society', 'car',
      ]);
    });
  });

  group('BillIcon.fromValue', () {
    test('reads a stored name, and none for null or unknown', () {
      expect(BillIcon.fromValue('power'), const Option<BillIcon>.of(BillIcon.power));
      expect(BillIcon.fromValue(null), const Option<BillIcon>.none());
      expect(BillIcon.fromValue('rocket'), const Option<BillIcon>.none());
    });
  });

  group('BillKind.icon', () {
    test('gives each onboarding chip its icon', () {
      expect(<BillIcon>[for (final BillKind kind in BillKind.values) kind.icon], <BillIcon>[
        BillIcon.home, BillIcon.loan, BillIcon.phone, BillIcon.internet, BillIcon.school, BillIcon.tv, //
      ]);
    });
  });
}
