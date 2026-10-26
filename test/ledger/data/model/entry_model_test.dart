import 'package:expense_tracker/core/db/db_schema.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/ledger/data/model/entry_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

const Map<String, Object?> _row = <String, Object?>{
  TransactionColumns.id: 4,
  TransactionColumns.amountMinor: 6000,
  TransactionColumns.currency: 'INR',
  TransactionColumns.kind: 'out',
  TransactionColumns.categoryId: 1,
  TransactionColumns.date: '2026-10-26',
  TransactionColumns.note: 'Chai',
  TransactionColumns.recurringId: null,
  TransactionColumns.createdAt: '2026-10-26T10:30:00.000',
};

void main() {
  group('EntryModel', () {
    test('reads a full row and writes it back unchanged', () {
      final EntryModel model = EntryModel.fromRow(_row).getOrElse((Failure f) => fail(f.message));
      expect(model.note, 'Chai');
      expect(model.toRow(), _row);
    });

    test('omits the id when inserting a new row', () {
      final EntryModel model = EntryModel.fromRow(_row).getOrElse((Failure f) => fail(f.message));
      final EntryModel unsaved = EntryModel(
        amountMinor: model.amountMinor,
        currency: model.currency,
        kind: model.kind,
        categoryId: model.categoryId,
        date: model.date,
        createdAt: model.createdAt,
      );
      expect(unsaved.toRow().containsKey(TransactionColumns.id), isFalse);
    });

    test('returns InvalidDataFailure for a wrongly typed or missing column', () {
      final Either<Failure, EntryModel> wrongType = EntryModel.fromRow(<String, Object?>{..._row, TransactionColumns.amountMinor: '60'});
      final Either<Failure, EntryModel> missing =
          EntryModel.fromRow(Map<String, Object?>.of(_row)..remove(TransactionColumns.date));
      expect(wrongType.getLeft().toNullable(), isA<InvalidDataFailure>());
      expect(missing.getLeft().toNullable(), isA<InvalidDataFailure>());
    });
  });
}
