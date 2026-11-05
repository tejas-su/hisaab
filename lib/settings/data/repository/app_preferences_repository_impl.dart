import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';
import '../../../core/errors/failure.dart';
import '../../domain/repository/app_preferences_repository.dart';
import '../datasource/preferences_local_data_source.dart';

/// [AppPreferencesRepository] over the `settings` table.
final class AppPreferencesRepositoryImpl implements AppPreferencesRepository {
  const AppPreferencesRepositoryImpl({required this._preferences});

  final PreferencesLocalDataSource _preferences;

  @override
  TaskEither<Failure, bool> onboardingDone() => dbTask(() => _preferences.read(SettingKeys.onboardingDone))
      .map((String? value) => value == SqflitePreferencesLocalDataSource.done);

  @override
  TaskEither<Failure, Unit> markOnboardingDone() => dbTask(() async {
        await _preferences.markOnboardingDone();
        return unit;
      });

  @override
  TaskEither<Failure, Option<String>> onboardingDraft() =>
      dbTask(() => _preferences.read(SettingKeys.onboardingDraft)).map(Option<String>.fromNullable);

  @override
  TaskEither<Failure, Unit> saveOnboardingDraft(String json) => dbTask(() async {
        await _preferences.write(SettingKeys.onboardingDraft, json);
        return unit;
      });

  @override
  TaskEither<Failure, Option<bool>> billRemindersChoice() => dbTask(() => _preferences.read(SettingKeys.billReminders))
      .map((String? value) => Option<String>.fromNullable(value).map((String stored) => stored == _yes));

  @override
  TaskEither<Failure, Unit> saveBillRemindersChoice({required bool remind}) => dbTask(() async {
        await _preferences.write(SettingKeys.billReminders, remind ? _yes : _no);
        return unit;
      });

  static const String _yes = '1';
  static const String _no = '0';
}
