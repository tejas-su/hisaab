import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/data/mapper/recurring_mapper.dart';
import 'package:hisaab/ledger/data/model/recurring_model.dart';
import 'package:hisaab/ledger/domain/entities/amount_mode.dart';
import 'package:hisaab/ledger/domain/entities/bill_icon.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';
import 'package:hisaab/ledger/domain/entities/frequency.dart';
import 'package:hisaab/ledger/domain/entities/recurring_draft.dart';
import 'package:hisaab/ledger/domain/entities/recurring_rule.dart';
import 'package:hisaab/ledger/domain/entities/schedule.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

RecurringModel _model({
  int? id = 3,
  String frequency = 'monthly',
  String anchor = '2026-01-31',
  String nextDue = '2026-10-31',
  String? icon,
  String amountMode = 'fixed',
  int? targetMinor,
  int? targetReachedFor,
  String? targetReachedOn,
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
      amountMode: amountMode,
      targetMinor: targetMinor,
      targetReachedFor: targetReachedFor,
      targetReachedOn: targetReachedOn,
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
  group('RecurringMapper amount mode (D123)', () {
    test('reads each stored mode', () {
      expect(RecurringMapper.toEntity(_model(amountMode: 'varies')).map((RecurringRule r) => r.amountMode),
          Either<Failure, AmountMode>.right(AmountMode.varies));
      expect(RecurringMapper.toEntity(_model(amountMode: 'card')).map((RecurringRule r) => r.amountMode),
          Either<Failure, AmountMode>.right(AmountMode.card));
      expect(RecurringMapper.toEntity(_model()).map((RecurringRule r) => r.amountMode),
          Either<Failure, AmountMode>.right(AmountMode.fixed));
    });

    test('an unknown mode is InvalidDataFailure', () {
      expect(RecurringMapper.toEntity(_model(amountMode: 'weird')).getLeft().toNullable(), isA<InvalidDataFailure>());
    });

    test('writes the mode', () {
      const RecurringDraft card = RecurringDraft(
        label: 'Credit card',
        amount: Money(800000),
        kind: EntryKind.spent,
        categoryId: 12,
        schedule: Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 5)),
        nextDue: CalendarDate(2026, 11, 5),
        amountMode: AmountMode.card,
      );
      expect(RecurringMapper.toModel(card).amountMode, 'card');
      expect(RecurringMapper.toModel(_draft).amountMode, 'fixed');
    });
  });

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

  group('RecurringMapper saving target (BR-23)', () {
    test('toModel then toEntity round-trips the three target fields', () {
      final RecurringDraft draft = RecurringDraft(
        label: 'RD',
        amount: Money.fromMajor(1000),
        kind: EntryKind.saved,
        categoryId: 7,
        schedule: _draft.schedule,
        nextDue: _draft.nextDue,
        target: some(Money.fromMajor(50000)),
        targetReachedFor: some(Money.fromMajor(50000)),
        targetReachedOn: some(const CalendarDate(2026, 11, 23)),
      );
      final RecurringRule rule = RecurringMapper.toEntity(RecurringMapper.toModel(draft, id: 3)).getOrElse((Failure f) => throw f);
      expect(rule.target, some(Money.fromMajor(50000)));
      expect(rule.targetReachedFor, some(Money.fromMajor(50000)));
      expect(rule.targetReachedOn, some(const CalendarDate(2026, 11, 23)));
      expect(rule.draft, draft);
    });

    test('null columns map to none', () {
      final RecurringRule rule = RecurringMapper.toEntity(_model()).getOrElse((Failure f) => throw f);
      expect(rule.target, const Option<Money>.none());
      expect(rule.targetReachedFor, const Option<Money>.none());
      expect(rule.targetReachedOn, const Option<CalendarDate>.none());
    });

    test('a bad reached-on date is InvalidDataFailure', () {
      expect(RecurringMapper.toEntity(_model(targetReachedOn: 'nope')).getLeft().toNullable(), isA<InvalidDataFailure>());
    });

    test('copyWith replaces and clears the target fields', () {
      final RecurringRule rule = RecurringMapper.toEntity(_model(targetMinor: 100)).getOrElse((Failure f) => throw f);
      final RecurringRule set = rule.copyWith(
        target: some(Money.fromMajor(5)),
        targetReachedFor: some(Money.fromMajor(5)),
        targetReachedOn: some(const CalendarDate(2026, 1, 1)),
      );
      expect(set.target, some(Money.fromMajor(5)));
      expect(set.targetReachedFor, some(Money.fromMajor(5)));
      expect(set.targetReachedOn, some(const CalendarDate(2026, 1, 1)));
      expect(set.copyWith(target: const Option<Money>.none()).target, const Option<Money>.none());
    });
  });
}
