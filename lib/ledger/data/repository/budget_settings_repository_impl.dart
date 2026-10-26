import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';
import '../../../core/errors/failure.dart';
import '../../../core/money/money.dart';
import '../../../core/time/month_start.dart';
import '../../domain/entities/budget_settings.dart';
import '../../domain/repository/budget_settings_repository.dart';
import '../datasource/budget_settings_local_data_source.dart';

/// [BudgetSettingsRepository] over the `settings` table; missing keys fall back to defaults.
final class BudgetSettingsRepositoryImpl implements BudgetSettingsRepository {
  const BudgetSettingsRepositoryImpl({required this._settings});

  final BudgetSettingsLocalDataSource _settings;

  @override
  TaskEither<Failure, BudgetSettings> read() =>
      dbTask(() => _settings.values(<String>[SettingKeys.monthStart, SettingKeys.keepAsideMinor])).chainEither(
        (Map<String, String> values) => _monthStart(values[SettingKeys.monthStart]).flatMap(
          (MonthStart monthStart) => _keepAside(values[SettingKeys.keepAsideMinor]).map(
            (Money keepAside) => BudgetSettings(monthStart: monthStart, keepAside: keepAside),
          ),
        ),
      );

  static Either<Failure, MonthStart> _monthStart(String? value) => switch (value) {
        null || MonthStartValues.payday => Either<Failure, MonthStart>.right(MonthStart.payday),
        MonthStartValues.firstOfMonth => Either<Failure, MonthStart>.right(MonthStart.firstOfMonth),
        _ => Either<Failure, MonthStart>.left(InvalidDataFailure('Unknown month start "$value"')),
      };

  static Either<Failure, Money> _keepAside(String? value) {
    if (value == null) {
      return Either<Failure, Money>.right(Money.zero);
    }
    final int? minor = int.tryParse(value);
    return minor == null || minor < 0
        ? Either<Failure, Money>.left(InvalidDataFailure('Bad keep-aside "$value"'))
        : Either<Failure, Money>.right(Money(minor));
  }
}
