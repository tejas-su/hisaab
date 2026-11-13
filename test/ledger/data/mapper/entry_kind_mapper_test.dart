import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/ledger/data/mapper/entry_kind_mapper.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';

void main() {
  group('EntryKindMapper', () {
    test('used maps to "used" and back (BR-19)', () {
      expect(EntryKindMapper.toValue(EntryKind.used), 'used');
      expect(EntryKindMapper.fromValue('used'), Either<Failure, EntryKind>.right(EntryKind.used));
    });

    test('an unknown value is InvalidDataFailure', () {
      expect(EntryKindMapper.fromValue('gift').getLeft().toNullable(), isA<InvalidDataFailure>());
    });
  });
}
