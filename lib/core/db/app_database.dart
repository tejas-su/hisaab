import 'package:fpdart/fpdart.dart';
import 'package:sqflite/sqflite.dart';

import '../errors/failure.dart';
import 'migrations/migrations.dart';

/// The app's single SQLite database, opened once at start-up and injected into data sources.
final class AppDatabase {
  AppDatabase._(this.db);

  /// File name inside the platform databases directory.
  static const String fileName = 'hisaab.db';

  /// Current schema version: one per entry in [migrations].
  static int get schemaVersion => migrations.length;

  /// The open connection; only data sources may use it.
  final Database db;

  /// Opens (creating or upgrading as needed) the database at [path] through [factory].
  ///
  /// Returns [Right] with the open database, or [Left] with [DatabaseFailure] if the file
  /// can't be opened or a migration fails. Every migration step runs inside sqflite's open
  /// transaction, so a failed upgrade leaves the previous version intact; downgrades are
  /// refused rather than wiping data. Pass `singleInstance: false` in tests that open
  /// several in-memory databases.
  static TaskEither<Failure, AppDatabase> open({
    required DatabaseFactory factory,
    required String path,
    bool singleInstance = true,
  }) =>
      TaskEither<Failure, AppDatabase>.tryCatch(
        () async => AppDatabase._(
          await factory.openDatabase(path, options: _options(singleInstance: singleInstance)),
        ),
        (Object error, StackTrace _) => DatabaseFailure(error),
      );

  static OpenDatabaseOptions _options({required bool singleInstance}) => OpenDatabaseOptions(
        version: schemaVersion,
        singleInstance: singleInstance,
        onConfigure: (Database db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (Database db, int version) => runMigrations(db, from: 0, to: version),
        onUpgrade: (Database db, int oldVersion, int newVersion) =>
            runMigrations(db, from: oldVersion, to: newVersion),
      );

  /// Closes the connection.
  Future<void> close() => db.close();
}
