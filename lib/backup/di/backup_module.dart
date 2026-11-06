import 'package:get_it/get_it.dart';

import '../../core/db/app_database.dart';
import '../../core/notifications/bill_reminders.dart';
import '../data/datasource/backup_local_data_source.dart';
import '../data/platform/backup_files.dart';
import '../data/repository/backup_repository_impl.dart';
import '../domain/repository/backup_repository.dart';
import '../domain/usecase/delete_everything.dart';

/// Registers backup, restore and *Delete everything* (D139); needs the core services first.
void registerBackupServices(GetIt getIt) {
  final AppDatabase database = getIt<AppDatabase>();
  final BackupRepository backups = BackupRepositoryImpl(
    source: SqfliteBackupLocalDataSource(database: database, scratch: database.factory),
    files: const FilePickerBackupFiles(),
  );
  getIt
    ..registerSingleton<BackupRepository>(backups)
    ..registerSingleton<DeleteEverything>(DeleteEverything(backups: backups, reminders: getIt<BillReminders>()));
}
