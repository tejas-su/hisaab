import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/notifications/bill_reminder.dart';
import '../../../core/notifications/bill_reminders.dart';
import '../../../core/notifications/nudge_notice.dart';
import '../../../core/notifications/nudges.dart';
import '../../../core/usecases/use_case.dart';
import '../repository/backup_repository.dart';

/// Clears all hisaab data and every scheduled reminder and daily nudge (E125), so the app starts again at onboarding
/// (SPEC FR-SE-4 AC-8, BR-16). Backup files the user saved are not touched.
final class DeleteEverything implements UseCase<Unit, NoParams> {
  const DeleteEverything({required this._backups, required this._reminders, required this._nudges});

  final BackupRepository _backups;
  final BillReminders _reminders;
  final Nudges _nudges;

  @override
  TaskEither<Failure, Unit> call(NoParams params) => _backups.wipe().flatMap(
        // why: reminders and nudges are only cleared once the data is gone; a failed wipe keeps them.
        (Unit _) => TaskEither<Failure, Unit>.fromTask(
          Task<Unit>(() async {
            await _reminders.arm(const <BillReminder>[], keep: const <int>{});
            await _nudges.arm(const <NudgeNotice>[]);
            return unit;
          }),
        ),
      );
}
