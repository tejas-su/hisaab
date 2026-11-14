import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/time/pay_switch.dart';
import 'package:hisaab/ledger/domain/entities/budget_settings.dart';
import 'package:hisaab/ledger/domain/repository/budget_settings_repository.dart';
import 'package:fpdart/fpdart.dart';

/// A [BudgetSettingsRepository] returning [settings]; set [failure] to make it fail.
final class FakeBudgetSettingsRepository implements BudgetSettingsRepository {
  FakeBudgetSettingsRepository([this.settings = const BudgetSettings()]);

  BudgetSettings settings;
  Failure? failure;

  @override
  TaskEither<Failure, BudgetSettings> read() {
    final Failure? current = failure;
    return current == null
        ? TaskEither<Failure, BudgetSettings>.right(settings)
        : TaskEither<Failure, BudgetSettings>.left(current);
  }

  /// Whether the install line is used up.
  bool installSeen = false;

  /// Failure for [markInstallLineSeen] only.
  Failure? seenFailure;

  @override
  TaskEither<Failure, bool> installLineSeen() {
    final Failure? current = failure;
    return current == null ? TaskEither<Failure, bool>.right(installSeen) : TaskEither<Failure, bool>.left(current);
  }

  @override
  TaskEither<Failure, Unit> markInstallLineSeen() {
    final Failure? current = seenFailure ?? failure;
    if (current != null) {
      return TaskEither<Failure, Unit>.left(current);
    }
    installSeen = true;
    return TaskEither<Failure, Unit>.right(unit);
  }

  /// Failure for [addPaySwitch] only.
  Failure? switchFailure;

  @override
  TaskEither<Failure, Unit> addPaySwitch(PaySwitch change) {
    final Failure? current = switchFailure ?? failure;
    if (current != null) {
      return TaskEither<Failure, Unit>.left(current);
    }
    settings = BudgetSettings(monthStart: settings.monthStart, paySwitches: <PaySwitch>[...settings.paySwitches, change]);
    return TaskEither<Failure, Unit>.right(unit);
  }
}
