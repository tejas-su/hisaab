import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/data/mapper/recurring_mapper.dart';
import 'package:expense_tracker/ledger/data/model/recurring_model.dart';
import 'package:expense_tracker/ledger/domain/entities/bill_icon.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_kind.dart';
import 'package:expense_tracker/ledger/domain/entities/frequency.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_draft.dart';
import 'package:expense_tracker/ledger/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/ledger/domain/entities/schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

RecurringModel _model({
  int? id = 3,
  String frequency = 'monthly',
  String anchor = '2026-01-31',
  String nextDue = '2026-10-31',
  String? icon,
}) =>
    RecurringModel(
      id: id,
      label: 'Rent',
      amountMinor: 820000,
      currency: 'INR',
      kind: 'out',
      categoryId: 7,
      frequency: frequency,
      anchorDate: anchor,
      lastDayOfMonth: true,
      nextDue: nextDue,
      isIncomeSource: false,
      icon: icon,
    );

const RecurringDraft _draft = RecurringDraft(
  label: 'Rent',
  amount: Money(820000),
  kind: EntryKind.spent,
  categoryId: 7,
  schedule: Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 1, 31), lastDayOfMonth: true),
  nextDue: CalendarDate(2026, 10, 31),
);

void main() {
  group('RecurringMapper', () {
    test('maps a row to a rule', () {
      expect(
        RecurringMapper.toEntity(_model()),
        Either<Failure, RecurringRule>.right(
          RecurringRule(
            id: 3,
            label: _draft.label,
            amount: _draft.amount,
            kind: _draft.kind,
            categoryId: _draft.categoryId,
            schedule: _draft.schedule,
            nextDue: _draft.nextDue,
          ),
        ),
      );
    });

    test('maps a draft to a new row', () {
      expect(RecurringMapper.toModel(_draft), _model(id: null));
    });

    test('maps a draft with an id to that rule\'s row', () {
      expect(RecurringMapper.toModel(_draft, id: 3), _model());
    });

    for (final Frequency frequency in Frequency.values) {
      test('round-trips the ${frequency.name} frequency', () {
        final RecurringModel model = RecurringMapper.toModel(
          RecurringDraft(
            label: 'x',
            amount: const Money(100),
            kind: EntryKind.spent,
            categoryId: 1,
            schedule: Schedule(frequency: frequency, anchor: const CalendarDate(2026, 1, 1)),
            nextDue: const CalendarDate(2026, 1, 1),
          ),
        );
        final RecurringRule rule = RecurringMapper.toEntity(_model(frequency: model.frequency)).getOrElse((Failure f) => fail(f.message));
        expect(rule.schedule.frequency, frequency);
      });
    }

    test('round-trips a picked bill icon (D118)', () {
      final RecurringModel model = RecurringMapper.toModel(
        RecurringDraft(
          label: _draft.label,
          amount: _draft.amount,
          kind: _draft.kind,
          categoryId: _draft.categoryId,
          schedule: _draft.schedule,
          nextDue: _draft.nextDue,
          icon: const Option<BillIcon>.of(BillIcon.gas),
        ),
        id: 3,
      );
      expect(model.icon, 'gas');
      final RecurringRule rule = RecurringMapper.toEntity(model).getOrElse((Failure f) => fail(f.message));
      expect(rule.icon, const Option<BillIcon>.of(BillIcon.gas));
    });

    test('maps an unknown stored icon to none, keeping the bill (Review Focus 4)', () {
      final RecurringRule rule = RecurringMapper.toEntity(_model(icon: 'rocket')).getOrElse((Failure f) => fail(f.message));
      expect(rule.icon, const Option<BillIcon>.none());
      expect(rule.label, 'Rent');
    });

    final List<(String, RecurringModel)> bad = <(String, RecurringModel)>[
      ('an unknown frequency', _model(frequency: 'daily')),
      ('a bad anchor date', _model(anchor: 'soon')),
      ('a bad next date', _model(nextDue: '2026-13-01')),
      ('no id', _model(id: null)),
    ];
    for (final (String name, RecurringModel model) in bad) {
      test('returns InvalidDataFailure for $name', () {
        expect(RecurringMapper.toEntity(model).getLeft().toNullable(), isA<InvalidDataFailure>());
      });
    }
  });
}
