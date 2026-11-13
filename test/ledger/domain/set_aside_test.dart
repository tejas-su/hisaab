import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/ledger/domain/entities/recurring_rule.dart';
import 'package:hisaab/ledger/domain/entities/saving_totals.dart';
import 'package:hisaab/ledger/domain/entities/set_aside_summary.dart';
import 'package:hisaab/ledger/domain/set_aside.dart';

import '../../helpers/fixtures/ledger/worked_example.dart';

Money _rupees(int amount) => Money.fromMajor(amount);

SavingTotals _totals(Map<int, ({int putIn, int used})> bySaving, {bool anyUse = false}) => SavingTotals(
      bySaving: <int, ({Money putIn, Money used})>{
        for (final MapEntry<int, ({int putIn, int used})> e in bySaving.entries)
          e.key: (putIn: _rupees(e.value.putIn), used: _rupees(e.value.used)),
      },
      anyUse: anyUse,
    );

void main() {
  group('SetAside.of (BR-19, U3)', () {
    test('12 put-ins of ₹1,000 and no use: ₹12,000 set aside', () {
      expect(SetAside.of(_rupees(12000), Money.zero), _rupees(12000));
    });

    test('₹12,000 used: nothing is set aside', () {
      expect(SetAside.of(_rupees(12000), _rupees(12000)), Money.zero);
    });

    test('a put-in deleted after a use floors at ₹0, never negative (E99)', () {
      expect(SetAside.of(_rupees(11000), _rupees(12000)), Money.zero);
    });

    test('a part use leaves the rest', () {
      expect(SetAside.of(_rupees(12000), _rupees(4000)), _rupees(8000));
    });
  });

  group('SetAside.summarise (BR-19, U4, U5)', () {
    test('no savings give an empty summary', () {
      final SetAsideSummary summary = SetAside.summarise(<RecurringRule>[], const SavingTotals());

      expect(summary, const SetAsideSummary());
    });

    test('still set aside sums active savings only; a deleted saving leaves it (E98)', () {
      final SetAsideSummary summary = SetAside.summarise(
        <RecurringRule>[WorkedExample.insurance, WorkedExample.rd],
        _totals(<int, ({int putIn, int used})>{
          5: (putIn: 12000, used: 4000),
          4: (putIn: 5000, used: 0),
          99: (putIn: 7000, used: 0),
        }, anyUse: true),
      );

      expect(summary.perSaving, <int, Money>{5: _rupees(8000), 4: _rupees(5000)});
      expect(summary.stillSetAside, _rupees(13000));
      expect(summary.anyUse, isTrue);
    });

    test('put in extra belongs to no saving and adds nothing (E100)', () {
      final SetAsideSummary summary = SetAside.summarise(
        <RecurringRule>[WorkedExample.insurance],
        _totals(<int, ({int putIn, int used})>{5: (putIn: 1000, used: 0)}),
      );

      expect(summary.stillSetAside, _rupees(1000));
    });

    test('anyUse is true when a use exists even with ₹0 set aside', () {
      final SetAsideSummary summary = SetAside.summarise(
        <RecurringRule>[WorkedExample.insurance],
        _totals(<int, ({int putIn, int used})>{5: (putIn: 12000, used: 12000)}, anyUse: true),
      );

      expect(summary.stillSetAside, Money.zero);
      expect(summary.anyUse, isTrue);
    });

    test('a saving that was never put into has ₹0', () {
      final SetAsideSummary summary = SetAside.summarise(<RecurringRule>[WorkedExample.insurance], const SavingTotals());

      expect(summary.perSaving, <int, Money>{5: Money.zero});
    });
  });
}
