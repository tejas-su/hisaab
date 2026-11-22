import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/db/db_schema.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/habits/data/model/nudge_state_model.dart';

const Map<String, Object?> _fullRow = <String, Object?>{
  NudgeStateColumns.categoryId: 13,
  NudgeStateColumns.armedFor: '2026-10-26T12:15:00.000',
  NudgeStateColumns.ignoredStreak: 2,
  NudgeStateColumns.restUntil: '2026-11-25',
};

const NudgeStateModel _full = NudgeStateModel(
  categoryId: 13,
  armedFor: '2026-10-26T12:15:00.000',
  ignoredStreak: 2,
  restUntil: '2026-11-25',
);

void main() {
  group('NudgeStateModel (BR-22.12)', () {
    test('round-trips a full row', () {
      expect(NudgeStateModel.fromRow(_fullRow), Either<Failure, NudgeStateModel>.right(_full));
      expect(_full.toRow(), _fullRow);
    });

    test('equal rows are equal, and any column makes a difference', () {
      expect(_full, const NudgeStateModel(categoryId: 13, armedFor: '2026-10-26T12:15:00.000', ignoredStreak: 2, restUntil: '2026-11-25'));
      expect(_full, isNot(const NudgeStateModel(categoryId: 14, armedFor: '2026-10-26T12:15:00.000', ignoredStreak: 2, restUntil: '2026-11-25')));
      expect(_full, isNot(const NudgeStateModel(categoryId: 13, ignoredStreak: 2, restUntil: '2026-11-25')));
      expect(_full, isNot(const NudgeStateModel(categoryId: 13, armedFor: '2026-10-26T12:15:00.000', restUntil: '2026-11-25')));
      expect(_full, isNot(const NudgeStateModel(categoryId: 13, armedFor: '2026-10-26T12:15:00.000', ignoredStreak: 2)));
    });

    test('a bad column is an InvalidDataFailure', () {
      final Either<Failure, NudgeStateModel> read = NudgeStateModel.fromRow(<String, Object?>{..._fullRow, NudgeStateColumns.ignoredStreak: 'x'});
      expect(read.getLeft().toNullable(), isA<InvalidDataFailure>());
    });
  });
}
