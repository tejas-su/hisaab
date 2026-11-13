import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/data/mapper/entry_kind_mapper.dart';
import 'package:hisaab/ledger/data/mapper/entry_mapper.dart';
import 'package:hisaab/ledger/data/model/entry_model.dart';
import 'package:hisaab/ledger/domain/entities/entry.dart';
import 'package:hisaab/ledger/domain/entities/entry_kind.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

const EntryModel _model = EntryModel(
  id: 4,
  amountMinor: 6000,
  currency: 'INR',
  kind: 'out',
  categoryId: 1,
  date: '2026-10-26',
  note: 'Chai',
  recurringId: 2,
  createdAt: '2026-10-26T10:30:00.000',
);

final Entry _entry = Entry(
  id: 4,
  amount: const Money(6000),
  kind: EntryKind.spent,
  categoryId: 1,
  date: const CalendarDate(2026, 10, 26),
  createdAt: DateTime(2026, 10, 26, 10, 30),
  note: 'Chai',
  recurringId: 2,
);

EntryModel _withModel({String? kind, String? currency, String? date, String? createdAt, bool noId = false}) => EntryModel(
      id: noId ? null : _model.id,
      amountMinor: _model.amountMinor,
      currency: currency ?? _model.currency,
      kind: kind ?? _model.kind,
      categoryId: _model.categoryId,
      date: date ?? _model.date,
      createdAt: createdAt ?? _model.createdAt,
    );

void main() {
  group('EntryMapper', () {
    test('maps a row to an entry', () {
      expect(EntryMapper.toEntity(_model), Either<Failure, Entry>.right(_entry));
    });

    test('maps an entry back to the same row', () {
      expect(
        EntryMapper.toModel(_entry.draft, createdAt: DateTime(2026, 10, 26, 10, 30), id: 4, recurringId: 2),
        _model,
      );
    });

    final List<(String, EntryModel)> bad = <(String, EntryModel)>[
      ('an unknown kind', _withModel(kind: 'sideways')),
      ('an unknown currency', _withModel(currency: 'XYZ')),
      ('a bad date', _withModel(date: '26/10/2026')),
      ('a bad created time', _withModel(createdAt: 'yesterday')),
      ('no id', _withModel(noId: true)),
    ];
    for (final (String name, EntryModel model) in bad) {
      test('returns InvalidDataFailure for $name', () {
        expect(EntryMapper.toEntity(model).getLeft().toNullable(), isA<InvalidDataFailure>());
      });
    }
  });

  group('EntryKindMapper', () {
    test('saved round-trips as "save" (D120)', () {
      expect(EntryKindMapper.toValue(EntryKind.saved), 'save');
      expect(EntryKindMapper.fromValue('save'), Either<Failure, EntryKind>.right(EntryKind.saved));
    });

    test('a card bill paid round-trips as "card" (D123)', () {
      expect(EntryKindMapper.toValue(EntryKind.cardPaid), 'card');
      expect(EntryKindMapper.fromValue('card'), Either<Failure, EntryKind>.right(EntryKind.cardPaid));
    });

    test('round-trips both kinds', () {
      for (final EntryKind kind in EntryKind.values) {
        expect(EntryKindMapper.fromValue(EntryKindMapper.toValue(kind)), Either<Failure, EntryKind>.right(kind));
      }
    });
  });
  group('EntryMapper savingId (D175)', () {
    test('savingId round-trips through toModel and toEntity', () {
      final EntryModel model = EntryMapper.toModel(_entry.draft, createdAt: DateTime(2026, 10, 26, 10, 30), id: 4, savingId: 5);

      expect(model.savingId, 5);
      expect(EntryMapper.toEntity(model).getRight().toNullable()?.savingId, 5);
    });

    test('a null savingId stays null', () {
      expect(EntryMapper.toEntity(_model).getRight().toNullable()?.savingId, isNull);
    });
  });

}
