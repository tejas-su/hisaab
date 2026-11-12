import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/habits/domain/usual_amount.dart';

typedef _Hit = ({Money amount, double weight});

List<_Hit> _hits(int count, int rupees, {double weight = 1}) =>
    List<_Hit>.filled(count, (amount: Money.fromMajor(rupees), weight: weight));

void main() {
  group('UsualAmount.pick (BR-17 rule 4)', () {
    test('7 of 10 equal weights is the usual amount', () {
      expect(UsualAmount.pick(<_Hit>[..._hits(7, 20), ..._hits(3, 30)]), Option<Money>.of(Money.fromMajor(20)));
    });

    test('69 of 100 is not', () {
      expect(UsualAmount.pick(<_Hit>[..._hits(69, 20), ..._hits(31, 30)]), const Option<Money>.none());
    });

    test('recent entries weigh more', () {
      expect(
        UsualAmount.pick(<_Hit>[..._hits(2, 20), ..._hits(3, 30, weight: 0.25)]),
        Option<Money>.of(Money.fromMajor(20)),
      );
    });

    test('a 50/50 split has no usual amount', () {
      expect(UsualAmount.pick(<_Hit>[..._hits(5, 20), ..._hits(5, 30)]), const Option<Money>.none());
    });

    test('no hits, none', () {
      expect(UsualAmount.pick(<_Hit>[]), const Option<Money>.none());
    });

    test('one hit is its own amount', () {
      expect(UsualAmount.pick(_hits(1, 45)), Option<Money>.of(Money.fromMajor(45)));
    });

    test('amounts one paisa apart are different amounts', () {
      expect(
        UsualAmount.pick(<_Hit>[
          (amount: const Money(2000), weight: 1),
          (amount: const Money(2001), weight: 1),
        ]),
        const Option<Money>.none(),
      );
    });

    test('the amount at the 9-digit cap is returned unchanged', () {
      expect(UsualAmount.pick(_hits(5, 999999999)), Option<Money>.of(Money.fromMajor(999999999)));
    });
  });
}
