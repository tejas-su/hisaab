import 'package:hisaab/core/db/app_database.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens a fresh, migrated in-memory database and closes it when the test ends.
Future<AppDatabase> openTestDatabase() async {
  sqfliteFfiInit();
  final Either<Failure, AppDatabase> opened =
      await AppDatabase.open(factory: databaseFactoryFfi, path: inMemoryDatabasePath, singleInstance: false).run();
  final AppDatabase database = opened.getOrElse((Failure failure) => fail(failure.message));
  addTearDown(database.close);
  return database;
}
