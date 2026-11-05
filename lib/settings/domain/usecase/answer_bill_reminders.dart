import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/notifications/bill_reminders.dart';
import '../../../core/usecases/use_case.dart';
import '../../../ledger/ledger.dart';
import '../repository/app_preferences_repository.dart';

/// Records the answer to "Remind you on the day it's due?" (spec §5, D126). The param is true
/// for *Remind me*: Android is then asked for the permission, and the reminders are armed.
///
/// A refused permission still counts as answered: nothing is asked again, and Home's line still
/// works (E-i).
final class AnswerBillReminders implements UseCase<Unit, bool> {
  const AnswerBillReminders({required this._preferences, required this._reminders, required this._arm});

  final AppPreferencesRepository _preferences;
  final BillReminders _reminders;
  final ArmBillReminders _arm;

  /// Returns [Right] with [unit], or [Left] with `DatabaseFailure` when the answer can't be
  /// saved (then nothing else happens) or the bills can't be read.
  @override
  TaskEither<Failure, Unit> call(bool params) => _preferences
      .saveBillRemindersChoice(remind: params)
      .flatMap((Unit _) => params ? _askAndroid() : TaskEither<Failure, Unit>.right(unit))
      .flatMap((Unit _) => _arm(params));

  TaskEither<Failure, Unit> _askAndroid() => TaskEither<Failure, Unit>(() async {
        await _reminders.requestPermission();
        return Either<Failure, Unit>.right(unit);
      });
}
