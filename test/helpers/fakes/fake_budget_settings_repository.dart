import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/ledger/domain/entities/budget_settings.dart';
import 'package:expense_tracker/ledger/domain/repository/budget_settings_repository.dart';
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
}
