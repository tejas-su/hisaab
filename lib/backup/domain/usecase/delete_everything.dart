import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/notifications/bill_reminder.dart';
import '../../../core/notifications/bill_reminders.dart';
import '../../../core/usecases/use_case.dart';
import '../repository/backup_repository.dart';

/// Clears all hisaab data and every scheduled reminder, so the app starts again at onboarding
/// (SPEC FR-SE-4 AC-8, BR-16). Backup files the user saved are not touched.
final class DeleteEverything implements UseCase<Unit, NoParams> {
  const DeleteEverything({required this._backups, required this._reminders});

  final BackupRepository _backups;
  final BillReminders _reminders;

  @override
  TaskEither<Failure, Unit> call(NoParams params) => _backups.wipe().flatMap(
        // why: reminders are only cleared once the data is gone; a failed wipe keeps both.
        (Unit _) => TaskEither<Failure, Unit>.fromTask(
          Task<Unit>(() async {
            await _reminders.arm(const <BillReminder>[], keep: const <int>{});
            return unit;
          }),
        ),
      );
}
