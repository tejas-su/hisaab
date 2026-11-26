import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/home/domain/entities/reached_line.dart';
import 'package:hisaab/ledger/ledger.dart';

import '../../../helpers/fixtures/ledger/worked_example.dart';

const CalendarDate _today = WorkedExample.today;
final Money _target = Money.fromMajor(12000);

RecurringRule _saving({
  int id = 5,
  Option<Money>? target,
  Option<Money> reachedFor = const Option<Money>.none(),
  Option<CalendarDate> reachedOn = const Option<CalendarDate>.none(),
}) =>
    RecurringRule(
      id: id,
      label: WorkedExample.insurance.label,
      amount: WorkedExample.insurance.amount,
      kind: WorkedExample.insurance.kind,
      categoryId: WorkedExample.insurance.categoryId,
      schedule: WorkedExample.insurance.schedule,
      nextDue: WorkedExample.insurance.nextDue,
      target: target ?? Option<Money>.of(_target),
      targetReachedFor: reachedFor,
      targetReachedOn: reachedOn,
    );

Option<ReachedLine> _pick(List<RecurringRule> rules, Map<int, Money> setAside) =>
    ReachedLine.pick(rules: rules, setAside: setAside, today: _today);

/// The reached line's candidate (SPEC BR-23 "Reached line on Home", FR-HO-3 AC-R1, AC-R4, E144 to E147).
void main() {
  group('ReachedLine.pick', () {
    test('a saving at its target, never shown, is pending', () {
      final RecurringRule saving = _saving();

      expect(_pick(<RecurringRule>[saving], <int, Money>{5: _target}), Option<ReachedLine>.of(ReachedLine(saving: saving, target: _target, pending: true)));
    });

    test('above the target counts as reached too', () {
      expect(_pick(<RecurringRule>[_saving()], <int, Money>{5: Money.fromMajor(13000)}).isSome(), isTrue);
    });

    test('below the target, with nothing set aside, or with no target: none', () {
      expect(_pick(<RecurringRule>[_saving()], <int, Money>{5: Money.fromMajor(11999)}), const Option<ReachedLine>.none());
      expect(_pick(<RecurringRule>[_saving()], const <int, Money>{}), const Option<ReachedLine>.none());
      expect(_pick(<RecurringRule>[_saving(target: const Option<Money>.none())], <int, Money>{5: _target}), const Option<ReachedLine>.none());
    });

    test('a bill is never a candidate', () {
      final RecurringRule bill = WorkedExample.rent.copyWith(target: Option<Money>.of(Money.fromMajor(1)));

      expect(_pick(<RecurringRule>[bill], <int, Money>{bill.id: _target}), const Option<ReachedLine>.none());
    });

    test('shown today: still the candidate, not pending, so it keeps the slot all day (F2)', () {
      final RecurringRule shown = _saving(reachedFor: Option<Money>.of(_target), reachedOn: const Option<CalendarDate>.of(_today));

      expect(_pick(<RecurringRule>[shown], <int, Money>{5: _target}), Option<ReachedLine>.of(ReachedLine(saving: shown, target: _target, pending: false)));
    });

    test('shown on an earlier day for the same target: never again (E145)', () {
      final RecurringRule shown = _saving(reachedFor: Option<Money>.of(_target), reachedOn: const Option<CalendarDate>.of(CalendarDate(2026, 10, 25)));

      expect(_pick(<RecurringRule>[shown], <int, Money>{5: _target}), const Option<ReachedLine>.none());
    });

    test('set while already reached (for = T, no day): no line (E147)', () {
      final RecurringRule set = _saving(reachedFor: Option<Money>.of(_target));

      expect(_pick(<RecurringRule>[set], <int, Money>{5: _target}), const Option<ReachedLine>.none());
    });

    test('a raised target reached again is pending once more (E146)', () {
      final Money raised = Money.fromMajor(15000);
      final RecurringRule saving = _saving(
        target: Option<Money>.of(raised),
        reachedFor: Option<Money>.of(_target),
        reachedOn: const Option<CalendarDate>.of(CalendarDate(2026, 9, 1)),
      );

      expect(_pick(<RecurringRule>[saving], <int, Money>{5: raised}), Option<ReachedLine>.of(ReachedLine(saving: saving, target: raised, pending: true)));
    });

    test('two pending: the rule saved first (E144)', () {
      final RecurringRule later = _saving(id: 9);
      final RecurringRule first = _saving(id: 6);

      expect(
        _pick(<RecurringRule>[later, first], <int, Money>{6: _target, 9: _target}).map((ReachedLine line) => line.saving.id),
        const Option<int>.of(6),
      );
    });

    test('one shown today beats an earlier-saved pending one (AC-R4, F2)', () {
      final RecurringRule pending = _saving(id: 6);
      final RecurringRule shown = _saving(id: 9, reachedFor: Option<Money>.of(_target), reachedOn: const Option<CalendarDate>.of(_today));

      expect(
        _pick(<RecurringRule>[pending, shown], <int, Money>{6: _target, 9: _target}).map((ReachedLine line) => line.saving.id),
        const Option<int>.of(9),
      );
    });

    test('shown today but set aside fell below the target: not shown, and not pending (E150)', () {
      final RecurringRule shown = _saving(reachedFor: Option<Money>.of(_target), reachedOn: const Option<CalendarDate>.of(_today));

      expect(_pick(<RecurringRule>[shown], <int, Money>{5: Money.fromMajor(7000)}), const Option<ReachedLine>.none());
    });
  });
}
