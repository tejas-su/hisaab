import 'dart:convert';

import 'package:expense_tracker/backup/data/mapper/backup_json_mapper.dart';
import 'package:expense_tracker/backup/domain/backup_failures.dart';
import 'package:expense_tracker/backup/domain/entities/backup_file.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  const int current = 3;

  Map<String, Object?> validJson({int version = 3, Object? onboardingDone = '1'}) => <String, Object?>{
        'app': 'hisaab',
        'schemaVersion': version,
        'madeOn': '2026-10-12',
        'tables': <String, Object?>{
          'categories': <Object?>[
            <String, Object?>{'id': 1, 'key': 'food', 'custom_name': null},
          ],
          'recurring': <Object?>[],
          'transactions': <Object?>[
            <String, Object?>{'id': 1, 'amount_minor': 12000, 'note': 'chai ☕', 'created_at': '2026-10-01T09:00:00.000'},
            <String, Object?>{'id': 2, 'amount_minor': 50000, 'note': null, 'created_at': '2026-10-02T09:00:00.000'},
          ],
          'settings': <Object?>[
            if (onboardingDone != null) <String, Object?>{'key': 'onboarding_done', 'value': onboardingDone},
          ],
        },
      };

  Either<Failure, BackupFile> decode(Object? json) =>
      BackupJsonMapper.decode(utf8.encode(jsonEncode(json)), currentVersion: current);

  group('BackupJsonMapper (SPEC BR-16, E14)', () {
    test('a valid file decodes with its date, version and entry count', () {
      final BackupFile file = decode(validJson()).getOrElse((Failure f) => fail(f.message));

      expect(file.schemaVersion, 3);
      expect(file.madeOn, const CalendarDate(2026, 10, 12));
      expect(file.entryCount, 2);
      expect(file.tables['transactions']!.first['note'], 'chai ☕');
    });

    test('encode then decode gives back the same file (NFR-5)', () {
      final BackupFile file = decode(validJson()).getOrElse((Failure f) => fail(f.message));

      final Either<Failure, BackupFile> again = BackupJsonMapper.decode(BackupJsonMapper.encode(file), currentVersion: current);

      expect(again, Either<Failure, BackupFile>.right(file));
    });

    test('the encoded file is marked as hisaab and keeps its version', () {
      final BackupFile file = decode(validJson()).getOrElse((Failure f) => fail(f.message));

      final Object? json = jsonDecode(utf8.decode(BackupJsonMapper.encode(file)));

      expect(json, isA<Map<String, Object?>>().having((Map<String, Object?> m) => m['app'], 'app', 'hisaab'));
    });

    test('bytes that are not JSON are not a backup', () {
      final Either<Failure, BackupFile> result = BackupJsonMapper.decode(<int>[0xff, 0xfe, 0x00], currentVersion: current);

      expect(result.getLeft().toNullable(), isA<NotABackupFailure>());
    });

    test('JSON from another app is not a backup', () {
      expect(decode(<String, Object?>{'name': 'x'}).getLeft().toNullable(), isA<NotABackupFailure>());
      expect(decode(<Object?>[1, 2]).getLeft().toNullable(), isA<NotABackupFailure>());
    });

    test('a file from a newer hisaab is refused as newer', () {
      expect(decode(validJson(version: 4)).getLeft().toNullable(), isA<NewerBackupFailure>());
    });

    test('an older version is accepted for migrating', () {
      expect(decode(validJson(version: 1)).getRight().toNullable()?.schemaVersion, 1);
    });

    test('a bad version or date is broken', () {
      expect(decode(validJson(version: 0)).getLeft().toNullable(), isA<BrokenBackupFailure>());
      expect(decode(<String, Object?>{...validJson(), 'madeOn': '12 Oct'}).getLeft().toNullable(), isA<BrokenBackupFailure>());
      expect(decode(<String, Object?>{...validJson(), 'schemaVersion': '3'}).getLeft().toNullable(), isA<BrokenBackupFailure>());
      expect(decode(<String, Object?>{...validJson(), 'madeOn': 20261012}).getLeft().toNullable(), isA<BrokenBackupFailure>());
    });

    test('a missing table or a row that is not an object is broken', () {
      final Map<String, Object?> noEntries = validJson();
      (noEntries['tables']! as Map<String, Object?>).remove('transactions');
      final Map<String, Object?> badRow = validJson();
      (badRow['tables']! as Map<String, Object?>)['recurring'] = <Object?>[1];
      final Map<String, Object?> nestedValue = validJson();
      (nestedValue['tables']! as Map<String, Object?>)['recurring'] = <Object?>[
        <String, Object?>{'id': <int>[1]},
      ];

      expect(decode(noEntries).getLeft().toNullable(), isA<BrokenBackupFailure>());
      expect(decode(badRow).getLeft().toNullable(), isA<BrokenBackupFailure>());
      expect(decode(nestedValue).getLeft().toNullable(), isA<BrokenBackupFailure>());
    });

    test('a backup made before onboarding finished is not a backup', () {
      expect(decode(validJson(onboardingDone: null)).getLeft().toNullable(), isA<NotABackupFailure>());
      expect(decode(validJson(onboardingDone: '0')).getLeft().toNullable(), isA<NotABackupFailure>());
    });

    test('a backup with no entries decodes (E41)', () {
      final Map<String, Object?> empty = validJson();
      (empty['tables']! as Map<String, Object?>)['transactions'] = <Object?>[];

      expect(decode(empty).getRight().toNullable()?.entryCount, 0);
    });
  });
}
