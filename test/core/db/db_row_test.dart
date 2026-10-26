import 'package:expense_tracker/core/db/db_row.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  const Map<String, Object?> row = <String, Object?>{'n': 5, 's': 'text', 'null': null, 'wrong': 1.5};

  group('DbRowExtensions', () {
    test('reads typed columns', () {
      expect(row.intAt('n'), 5);
      expect(row.stringAt('s'), 'text');
      expect(row.intOrNullAt('n'), 5);
      expect(row.stringOrNullAt('s'), 'text');
    });

    test('reads null columns as null', () {
      expect(row.intOrNullAt('null'), isNull);
      expect(row.stringOrNullAt('null'), isNull);
    });

    test('throws FormatException naming the column on a type mismatch or missing value', () {
      expect(() => row.intAt('wrong'), throwsA(isA<FormatException>().having((FormatException e) => e.message, 'message', contains('wrong'))));
      expect(() => row.stringAt('n'), throwsFormatException);
      expect(() => row.intAt('missing'), throwsFormatException);
      expect(() => row.stringOrNullAt('n'), throwsFormatException);
    });
  });

  group('readRow', () {
    test('wraps a good read in Right', () {
      expect(readRow('t', () => row.intAt('n')), Either<Failure, int>.right(5));
    });

    test('turns a bad read into InvalidDataFailure naming the table', () {
      final Failure failure = readRow('entries', () => row.intAt('s')).getLeft().toNullable()!;
      expect(failure, isA<InvalidDataFailure>());
      expect(failure.message, contains('entries'));
    });
  });

  group('dbTask', () {
    test('returns the result on success', () async {
      expect(await dbTask(() async => 3).run(), Either<Failure, int>.right(3));
    });

    test('returns the row failure for an unreadable row', () async {
      const InvalidDataFailure failure = InvalidDataFailure('bad row');
      final Either<Failure, int> result = await dbTask<int>(() async => requireRow(Either<Failure, int>.left(failure))).run();
      expect(result, Either<Failure, int>.left(failure));
    });

    test('returns DatabaseFailure for anything else', () async {
      final Either<Failure, int> result = await dbTask<int>(() async => throw StateError('locked')).run();
      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    });

    test('RowFailureException reads as its failure message', () {
      expect(const RowFailureException(InvalidDataFailure('bad row')).toString(), 'bad row');
    });

    test('requireRow returns a Right value', () {
      expect(requireRow(Either<Failure, int>.right(4)), 4);
    });
  });
}
