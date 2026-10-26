import 'package:get_it/get_it.dart';

import '../../core/db/app_database.dart';
import '../data/datasource/preferences_local_data_source.dart';
import '../data/repository/app_preferences_repository_impl.dart';
import '../domain/repository/app_preferences_repository.dart';

/// Registers the app preferences repository; needs the core services registered first.
void registerSettingsServices(GetIt getIt) => getIt.registerSingleton<AppPreferencesRepository>(
      AppPreferencesRepositoryImpl(preferences: SqflitePreferencesLocalDataSource(getIt<AppDatabase>())),
    );
