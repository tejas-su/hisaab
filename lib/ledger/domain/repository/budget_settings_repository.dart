import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/time/pay_switch.dart';
import '../entities/budget_settings.dart';

/// Reads the ledger-owned settings (DECISIONS D20) and records pay switches (D140).
abstract interface class BudgetSettingsRepository {
  /// Loads the settings, using defaults for any that were never set.
  ///
  /// Returns [Right] with the settings, or [Left] with `DatabaseFailure` or
  /// `InvalidDataFailure` for an unreadable stored value.
  TaskEither<Failure, BudgetSettings> read();

  /// Appends [change] to the stored pay switches.
  ///
  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure` or `InvalidDataFailure` when
  /// the stored switches can't be read.
  TaskEither<Failure, Unit> addPaySwitch(PaySwitch change);
}
