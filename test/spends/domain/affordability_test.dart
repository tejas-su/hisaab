import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/spends/domain/affordability.dart';
import 'package:hisaab/spends/domain/entities/afford_answer.dart';

Money _r(int rupees) => Money.fromMajor(rupees);

AffordAnswer _ask({
  required int room,
  required int price,
  int have = 0,
  int? usual,
  int days = 30,
}) =>
    Affordability.answer(AffordInputs(
      price: _r(price),
      have: _r(have),
      room: _r(room),
      days: days,
      usual: usual == null ? const None() : Some<Money>(_r(usual)),
    ));

void main() {
  group('Affordability.answer (BR-24)', () {
    test('owner_example: saveUp with the worked numbers', () {
      final AffordAnswer a = _ask(room: 32000, usual: 750, price: 127000, have: 60000);
      expect(a.verdict, AffordVerdict.saveUp);
      expect(a.floor, _r(900));
      expect(a.spare, _r(5000));
      expect(a.need, _r(67000));
      expect(a.putIns, const Some<int>(14));
      expect(a.savingPerDay, Some<Money>(_r(900)));
      expect(a.normalPerDay, _r(1066));
    });

    test('with_card', () {
      final AffordAnswer a = _ask(room: 95000, usual: 2000, price: 127000, have: 110000);
      expect(a.verdict, AffordVerdict.withCard);
      expect(a.floor, _r(2400));
      expect(a.spare, _r(23000));
      expect(a.cardPerDay, Some<Money>(_r(2600)));
    });

    test('from_savings', () {
      final AffordAnswer a = _ask(room: 95000, usual: 2000, price: 127000, have: 130000);
      expect(a.verdict, AffordVerdict.fromSavings);
      expect(a.need, Money.zero);
      expect(a.cardPerDay, isA<None>());
    });

    test('days_full: no spare', () {
      final AffordAnswer a = _ask(room: 32000, usual: 1000, price: 127000);
      expect(a.verdict, AffordVerdict.daysFull);
      expect(a.floor, _r(1200));
      expect(a.spare, Money.zero);
      expect(a.savingPerDay, isA<None>());
      expect(a.putIns, isA<None>());
    });

    test('need_equals_spare is withCard', () {
      final AffordAnswer a = _ask(room: 32000, usual: 750, price: 5000);
      expect(a.spare, _r(5000));
      expect(a.verdict, AffordVerdict.withCard);
    });

    test('need_one_paisa_over_spare is saveUp', () {
      final AffordAnswer a = Affordability.answer(AffordInputs(
        price: const Money(500001),
        have: Money.zero,
        room: _r(32000),
        days: 30,
        usual: Some<Money>(_r(750)),
      ));
      expect(a.verdict, AffordVerdict.saveUp);
      expect(a.putIns, const Some<int>(2));
    });

    test('too_early: no history and need above zero', () {
      final AffordAnswer a = _ask(room: 32000, price: 127000);
      expect(a.verdict, AffordVerdict.tooEarly);
      expect(a.floor, Money.zero);
      expect(a.spare, Money.zero);
      expect(a.cardPerDay, isA<None>());
      expect(a.savingPerDay, isA<None>());
      expect(a.putIns, isA<None>());
    });

    test('too_early_but_covered: need zero needs no history', () {
      final AffordAnswer a = _ask(room: 32000, price: 1000, have: 1000);
      expect(a.verdict, AffordVerdict.fromSavings);
    });

    test('floor_rounds_up_to_10', () {
      expect(_ask(room: 95000, usual: 751, price: 1000).floor, _r(910));
    });

    test('spare_rounds_down_to_500', () {
      // 5,499 over the floor: 900 x 30 = 27,000; room 32,499.
      final AffordAnswer a = _ask(room: 32499, usual: 750, price: 1000);
      expect(a.spare, _r(5000));
    });

    test('weekly_days', () {
      final AffordAnswer a = _ask(room: 10000, usual: 1000, price: 5000, days: 7);
      expect(a.spare, _r(1500));
    });

    test('nine_digit_cap does not overflow', () {
      final AffordAnswer a = _ask(room: 95000, usual: 2000, price: 999999999);
      expect(a.verdict, AffordVerdict.saveUp);
      expect(a.need, _r(999999999));
      expect(a.putIns, const Some<int>(43479));
    });
  });
}
