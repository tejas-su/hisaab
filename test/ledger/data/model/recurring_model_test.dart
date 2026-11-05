import 'package:expense_tracker/core/db/db_schema.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/ledger/data/model/recurring_model.dart';
import 'package:flutter_test/flutter_test.dart';

const Map<String, Object?> _row = <String, Object?>{
  RecurringColumns.id: 1,
  RecurringColumns.label: 'Salary',
  RecurringColumns.amountMinor: 4500000,
  RecurringColumns.currency: 'INR',
  RecurringColumns.kind: 'in',
  RecurringColumns.categoryId: 9,
  RecurringColumns.frequency: 'monthly',
  RecurringColumns.anchorDate: '2026-10-04',
  RecurringColumns.lastDayOfMonth: 0,
  RecurringColumns.nextDue: '2026-11-04',
  RecurringColumns.active: 1,
  RecurringColumns.isIncomeSource: 1,
  RecurringColumns.icon: null,
  RecurringColumns.amountMode: 'fixed',
};

void main() {
  group('RecurringModel', () {
    test('reads a row and writes it back as an active rule', () {
      final RecurringModel model = RecurringModel.fromRow(_row).getOrElse((Failure f) => fail(f.message));
      expect(model.isIncomeSource, isTrue);
      expect(model.lastDayOfMonth, isFalse);
      expect(model.toRow(), _row);
    });

    test('reads the 0/1 flags', () {
      final RecurringModel model = RecurringModel.fromRow(<String, Object?>{
        ..._row,
        RecurringColumns.lastDayOfMonth: 1,
        RecurringColumns.isIncomeSource: 0,
      }).getOrElse((Failure f) => fail(f.message));
      expect(model.lastDayOfMonth, isTrue);
      expect(model.isIncomeSource, isFalse);
      expect(model.toRow()[RecurringColumns.lastDayOfMonth], 1);
    });

    test('omits the id for a new rule', () {
      const RecurringModel model = RecurringModel(
        label: 'Rent',
        amountMinor: 820000,
        currency: 'INR',
        kind: 'out',
        categoryId: 7,
        frequency: 'monthly',
        anchorDate: '2026-10-05',
        lastDayOfMonth: false,
        nextDue: '2026-10-05',
        isIncomeSource: false,
      );
      expect(model.toRow().containsKey(RecurringColumns.id), isFalse);
    });

    test('reads and writes the bill icon (D118)', () {
      final RecurringModel model = RecurringModel.fromRow(<String, Object?>{..._row, RecurringColumns.icon: 'gas'})
          .getOrElse((Failure f) => fail(f.message));
      expect(model.icon, 'gas');
      expect(model.toRow()[RecurringColumns.icon], 'gas');
    });

    test('reads a row without the icon column as no icon', () {
      final RecurringModel model = RecurringModel.fromRow(<String, Object?>{..._row}..remove(RecurringColumns.icon))
          .getOrElse((Failure f) => fail(f.message));
      expect(model.icon, isNull);
    });

    test('reads and writes the amount mode (D123)', () {
      final RecurringModel model = RecurringModel.fromRow(<String, Object?>{..._row, RecurringColumns.amountMode: 'varies'})
          .getOrElse((Failure f) => fail(f.message));
      expect(model.amountMode, 'varies');
      expect(model.toRow()[RecurringColumns.amountMode], 'varies');
    });

    test('returns InvalidDataFailure for a bad column', () {
      expect(RecurringModel.fromRow(<String, Object?>{..._row, RecurringColumns.nextDue: 20261104}).isLeft(), isTrue);
    });
  });
}
