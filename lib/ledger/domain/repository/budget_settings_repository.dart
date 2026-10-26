import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../entities/budget_settings.dart';

/// Reads the ledger-owned settings (DECISIONS D20).
abstract interface class BudgetSettingsRepository {
  /// Loads the settings, using defaults for any that were never set.
  ///
  /// Returns [Right] with the settings, or [Left] with `DatabaseFailure` or
  /// `InvalidDataFailure` for an unreadable stored value.
  TaskEither<Failure, BudgetSettings> read();
}
