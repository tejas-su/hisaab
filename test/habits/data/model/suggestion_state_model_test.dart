import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/db/db_schema.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/habits/data/model/suggestion_state_model.dart';

const Map<String, Object?> _fullRow = <String, Object?>{
  SuggestionStateColumns.categoryId: 13,
  SuggestionStateColumns.quietOn: '2026-10-26',
  SuggestionStateColumns.restUntil: '2026-11-25',
  SuggestionStateColumns.forgottenAt: '2026-10-26T10:05:00.000',
  SuggestionStateColumns.askedOn: '2026-10-27',
};

const SuggestionStateModel _full = SuggestionStateModel(
  categoryId: 13,
  quietOn: '2026-10-26',
  restUntil: '2026-11-25',
  forgottenAt: '2026-10-26T10:05:00.000',
  askedOn: '2026-10-27',
);

void main() {
  group('SuggestionStateModel', () {
    test('round-trips a full row', () {
      expect(SuggestionStateModel.fromRow(_fullRow), Either<Failure, SuggestionStateModel>.right(_full));
      expect(_full.toRow(), _fullRow);
    });

    test('null columns are none', () {
      const Map<String, Object?> row = <String, Object?>{
        SuggestionStateColumns.categoryId: 13,
        SuggestionStateColumns.quietOn: null,
        SuggestionStateColumns.restUntil: null,
        SuggestionStateColumns.forgottenAt: null,
        SuggestionStateColumns.askedOn: null,
      };

      expect(
        SuggestionStateModel.fromRow(row),
        Either<Failure, SuggestionStateModel>.right(const SuggestionStateModel(categoryId: 13)),
      );
      expect(const SuggestionStateModel(categoryId: 13).toRow(), row);
    });

    final Map<String, Map<String, Object?>> badRows = <String, Map<String, Object?>>{
      'a missing category_id': <String, Object?>{..._fullRow}..remove(SuggestionStateColumns.categoryId),
      'a null category_id': <String, Object?>{..._fullRow, SuggestionStateColumns.categoryId: null},
      'a text category_id': <String, Object?>{..._fullRow, SuggestionStateColumns.categoryId: '13'},
      'a quiet_on that is not text': <String, Object?>{..._fullRow, SuggestionStateColumns.quietOn: 20261026},
      'a rest_until that is not text': <String, Object?>{..._fullRow, SuggestionStateColumns.restUntil: 20261125},
      'a forgotten_at that is not text': <String, Object?>{..._fullRow, SuggestionStateColumns.forgottenAt: 1},
    };
    for (final MapEntry<String, Map<String, Object?>> bad in badRows.entries) {
      test('${bad.key} is InvalidDataFailure', () {
        expect(SuggestionStateModel.fromRow(bad.value).getLeft().toNullable(), isA<InvalidDataFailure>());
      });
    }

    test('compares by its columns', () {
      expect(_full, SuggestionStateModel.fromRow(_fullRow).getOrElse((Failure f) => fail(f.message)));
      expect(_full, isNot(const SuggestionStateModel(categoryId: 13, quietOn: '2026-10-26')));
    });

    test('a v4-shaped row with no asked_on reads none (BR-17)', () {
      final Map<String, Object?> v4 = <String, Object?>{..._fullRow}..remove(SuggestionStateColumns.askedOn);

      expect(SuggestionStateModel.fromRow(v4).getOrElse((Failure f) => fail(f.message)).askedOn, isNull);
    });

    test('an asked_on that is not text is InvalidDataFailure', () {
      final Map<String, Object?> bad = <String, Object?>{..._fullRow, SuggestionStateColumns.askedOn: 20261027};

      expect(SuggestionStateModel.fromRow(bad).getLeft().toNullable(), isA<InvalidDataFailure>());
    });
  });
}
