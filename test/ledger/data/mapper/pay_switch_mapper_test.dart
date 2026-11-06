import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_rule.dart';
import 'package:expense_tracker/core/time/pay_switch.dart';
import 'package:expense_tracker/ledger/data/mapper/pay_switch_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const CalendarDate oct26 = CalendarDate(2026, 10, 26);

  group('PaySwitchMapper', () {
    for (final PayRule rule in <PayRule>[
      const MonthlyOnDay(4),
      const LastDayOfMonth(),
      const WeeklyOn(DateTime.friday),
      const IrregularIncome(),
    ]) {
      test('round-trips a switch from $rule', () {
        final List<PaySwitch> switches = <PaySwitch>[PaySwitch(on: oct26, from: rule)];
        expect(PaySwitchMapper.fromText(PaySwitchMapper.toText(switches)).getOrElse((Failure f) => fail('unexpected $f')), switches);
      });
    }

    test('keeps the order', () {
      const List<PaySwitch> switches = <PaySwitch>[
        PaySwitch(on: oct26, from: MonthlyOnDay(4)),
        PaySwitch(on: CalendarDate(2026, 11, 10), from: MonthlyOnDay(25)),
      ];
      expect(PaySwitchMapper.fromText(PaySwitchMapper.toText(switches)).getOrElse((Failure _) => const <PaySwitch>[]), switches);
    });

    test('no value is no switches', () {
      expect(PaySwitchMapper.fromText(null).getOrElse((Failure f) => fail('unexpected $f')), isEmpty);
    });

    for (final String bad in <String>[
      'not json',
      '{}',
      '[1]',
      '[{"on":"2026-10-26"}]',
      '[{"on":"26 Oct","rule":"irregular"}]',
      '[{"on":"2026-10-26","rule":"monthly"}]',
      '[{"on":"2026-10-26","rule":"monthly","day":32}]',
      '[{"on":"2026-10-26","rule":"weekly","weekday":0}]',
      '[{"on":"2026-10-26","rule":"yearly"}]',
    ]) {
      test('refuses "$bad" with InvalidDataFailure', () {
        expect(PaySwitchMapper.fromText(bad).getLeft().toNullable(), isA<InvalidDataFailure>());
      });
    }
  });
}
