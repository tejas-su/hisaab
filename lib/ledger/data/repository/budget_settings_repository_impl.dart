import 'package:fpdart/fpdart.dart';

import '../../../core/time/pay_switch.dart';
import '../mapper/pay_switch_mapper.dart';
import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';
import '../../../core/errors/failure.dart';
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
      dbTask(() => _settings.values(<String>[SettingKeys.monthStart, SettingKeys.paySwitches])).chainEither(
        (Map<String, String> values) => _monthStart(values[SettingKeys.monthStart]).flatMap(
          (MonthStart monthStart) => PaySwitchMapper.fromText(values[SettingKeys.paySwitches])
              .map((List<PaySwitch> switches) => BudgetSettings(monthStart: monthStart, paySwitches: switches)),
        ),
      );

  // why: one key holds the whole list, so a change reads it, appends and writes it back.
  @override
  TaskEither<Failure, Unit> addPaySwitch(PaySwitch change) => read().flatMap(
        (BudgetSettings settings) => dbTask(() async {
          await _settings.write(SettingKeys.paySwitches, PaySwitchMapper.toText(<PaySwitch>[...settings.paySwitches, change]));
          return unit;
        }),
      );

  static Either<Failure, MonthStart> _monthStart(String? value) => switch (value) {
        null || MonthStartValues.payday => Either<Failure, MonthStart>.right(MonthStart.payday),
        MonthStartValues.firstOfMonth => Either<Failure, MonthStart>.right(MonthStart.firstOfMonth),
        _ => Either<Failure, MonthStart>.left(InvalidDataFailure('Unknown month start "$value"')),
      };
}
