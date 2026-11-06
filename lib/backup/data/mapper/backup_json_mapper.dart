import 'dart:convert';
import 'dart:typed_data';

import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_schema.dart';
import '../../../core/errors/failure.dart';
import '../../../core/time/calendar_date.dart';
import '../../domain/backup_failures.dart';
import '../../domain/entities/backup_file.dart';

/// Turns a [BackupFile] into the JSON backup file and back (SPEC BR-16).
///
/// The file is `{"app": "hisaab", "schemaVersion": n, "madeOn": "YYYY-MM-DD", "tables": {name:
/// [row, …]}}`, each row as stored. Decoding checks the shape only; the rows themselves are checked
/// when they are loaded into a scratch database.
abstract final class BackupJsonMapper {
  static const String _app = 'hisaab';
  static const String _appKey = 'app';
  static const String _versionKey = 'schemaVersion';
  static const String _madeOnKey = 'madeOn';
  static const String _tablesKey = 'tables';

  /// Tables every backup has had since schema v1.
  static const List<String> requiredTables = <String>[
    Tables.categories,
    Tables.recurring,
    Tables.transactions,
    Tables.settings,
  ];

  /// The UTF-8 JSON bytes of [file].
  static Uint8List encode(BackupFile file) => utf8.encode(
        jsonEncode(<String, Object?>{
          _appKey: _app,
          _versionKey: file.schemaVersion,
          _madeOnKey: file.madeOn.toIso(),
          _tablesKey: file.tables,
        }),
      );

  /// Reads a backup file's [bytes] for an app at [currentVersion].
  ///
  /// Returns [Left] with [NotABackupFailure] when it isn't hisaab JSON or onboarding was never
  /// finished, [NewerBackupFailure] when it comes from a newer schema, and [BrokenBackupFailure]
  /// when a field or table is missing or malformed.
  static Either<Failure, BackupFile> decode(List<int> bytes, {required int currentVersion}) =>
      _json(bytes).flatMap((Map<String, Object?> json) => _file(json, currentVersion));

  static Either<Failure, Map<String, Object?>> _json(List<int> bytes) {
    final Object? json = Either<Object, Object?>.tryCatch(
      () => jsonDecode(utf8.decode(bytes)),
      (Object error, StackTrace _) => error,
    ).toNullable();
    if (json is Map<String, Object?> && json[_appKey] == _app) {
      return Either<Failure, Map<String, Object?>>.right(json);
    }
    return Either<Failure, Map<String, Object?>>.left(const NotABackupFailure('not hisaab backup JSON'));
  }

  static Either<Failure, BackupFile> _file(Map<String, Object?> json, int currentVersion) {
    final Object? version = json[_versionKey];
    if (version is! int || version < 1) {
      return Either<Failure, BackupFile>.left(const BrokenBackupFailure('bad schemaVersion'));
    }
    if (version > currentVersion) {
      return Either<Failure, BackupFile>.left(NewerBackupFailure('schemaVersion $version > $currentVersion'));
    }
    final Object? madeOn = json[_madeOnKey];
    final Either<Failure, CalendarDate> date = madeOn is String
        ? CalendarDate.parse(madeOn).mapLeft((Failure _) => const BrokenBackupFailure('bad madeOn'))
        : Either<Failure, CalendarDate>.left(const BrokenBackupFailure('no madeOn'));
    return date.flatMap(
      (CalendarDate day) => _tables(json[_tablesKey]).flatMap(_finished).map(
            (Map<String, List<Map<String, Object?>>> tables) => BackupFile(
              schemaVersion: version,
              madeOn: day,
              tables: tables,
              entryCount: tables[Tables.transactions]?.length ?? 0,
            ),
          ),
    );
  }

  static Either<Failure, Map<String, List<Map<String, Object?>>>> _tables(Object? raw) {
    if (raw is! Map<String, Object?> || !requiredTables.every(raw.containsKey)) {
      return Either<Failure, Map<String, List<Map<String, Object?>>>>.left(const BrokenBackupFailure('tables missing'));
    }
    final Map<String, Option<List<Map<String, Object?>>>> rows =
        raw.map((String name, Object? value) => MapEntry<String, Option<List<Map<String, Object?>>>>(name, _rows(value)));
    if (rows.values.any((Option<List<Map<String, Object?>>> table) => table.isNone())) {
      return Either<Failure, Map<String, List<Map<String, Object?>>>>.left(const BrokenBackupFailure('bad rows'));
    }
    return Either<Failure, Map<String, List<Map<String, Object?>>>>.right(
      rows.map(
        (String name, Option<List<Map<String, Object?>>> table) =>
            MapEntry<String, List<Map<String, Object?>>>(name, table.getOrElse(() => const <Map<String, Object?>>[])),
      ),
    );
  }

  static Option<List<Map<String, Object?>>> _rows(Object? value) {
    if (value is! List<Object?>) {
      return const Option<List<Map<String, Object?>>>.none();
    }
    final bool valid = value.every((Object? row) => row is Map<String, Object?> && row.values.every(_isScalar));
    return valid
        ? Option<List<Map<String, Object?>>>.of(value.whereType<Map<String, Object?>>().toList(growable: false))
        : const Option<List<Map<String, Object?>>>.none();
  }

  static bool _isScalar(Object? value) => value == null || value is String || value is num;

  static Either<Failure, Map<String, List<Map<String, Object?>>>> _finished(
    Map<String, List<Map<String, Object?>>> tables,
  ) {
    final bool done = (tables[Tables.settings] ?? const <Map<String, Object?>>[]).any(
      (Map<String, Object?> row) =>
          row[SettingsColumns.key] == SettingKeys.onboardingDone && row[SettingsColumns.value] == _onboardingDone,
    );
    return done
        ? Either<Failure, Map<String, List<Map<String, Object?>>>>.right(tables)
        : Either<Failure, Map<String, List<Map<String, Object?>>>>.left(const NotABackupFailure('onboarding never finished'));
  }

  // why: the settings feature stores '1' once onboarding is finished (PreferencesLocalDataSource.done);
  // the backup feature reads the row raw, so it can't import that data source.
  static const String _onboardingDone = '1';
}
