import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'app/app_services.dart';
import 'app/font_licenses.dart';
import 'app/hisaab_app.dart';
import 'core/db/app_database.dart';
import 'core/errors/failure.dart';
import 'core/logging/app_bloc_observer.dart';
import 'core/logging/app_logger.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'en_IN';
  await initializeDateFormatting('en_IN');
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  registerFontLicenses();
  Bloc.observer = const AppBlocObserver();

  final String path = p.join(await getDatabasesPath(), AppDatabase.fileName);
  final Either<Failure, AppDatabase> opened = await AppDatabase.open(factory: databaseFactory, path: path).run();

  opened.match(
    (Failure failure) {
      AppLogger.log(tag: 'startup.database_failed', data: <String, Object?>{'message': failure.message});
      runApp(const HisaabApp.startupFailed());
    },
    (AppDatabase database) {
      registerAppServices(GetIt.I, database: database);
      runApp(HisaabApp(getIt: GetIt.I));
    },
  );
}
