import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/ledger/data/mapper/entry_mapper.dart';
import 'package:hisaab/ledger/data/model/entry_model.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';

EntryModel _model(String? key) => EntryModel(
      id: 1,
      amountMinor: 420000,
      currency: 'INR',
      kind: 'out',
      categoryId: 7,
      date: '2026-10-26',
      createdAt: '2026-10-26T10:30:00.000',
      categoryKey: key,
    );

Entry _entity(String? key) => EntryMapper.toEntity(_model(key)).getOrElse((Failure f) => fail(f.message));

void main() {
  group('EntryMapper.isNotLogged (BR-18)', () {
    test('not_logged and not_logged_in are fixes; food, saved and no key are not', () {
      expect(_entity('not_logged').isNotLogged, isTrue);
      expect(_entity('not_logged_in').isNotLogged, isTrue);
      expect(_entity('food').isNotLogged, isFalse);
      expect(_entity('saved').isNotLogged, isFalse);
      expect(_entity(null).isNotLogged, isFalse);
    });

    test('the flag is part of an entry\'s value', () {
      expect(_entity('not_logged'), isNot(_entity('food')));
    });
  });
}
