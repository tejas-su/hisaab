import 'package:flutter/widgets.dart';
import 'package:fpdart/fpdart.dart';
import 'package:intl/intl.dart';

import '../../../core/time/calendar_date.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../bloc/your_hisaab_state.dart';

/// The words of the backup screens (copy deck 34), read from a [BuildContext].
extension BackupCopy on BuildContext {
  AppLocalizations get _strings => AppLocalizations.of(this);

  /// [date] as "12 Oct".
  String backupDay(CalendarDate date) =>
      DateFormat('d MMM', Localizations.localeOf(this).toString()).format(DateTime(date.year, date.month, date.day));

  /// The *Back up* row's second line: "Backed up today", "Last backed up 12 Oct" or "Not backed up yet".
  String lastBackup(Option<CalendarDate> last, CalendarDate today) => last.match(
        () => _strings.backUpNever,
        (CalendarDate day) => day == today ? _strings.backUpToday : _strings.backUpLast(backupDay(day)),
      );

  /// The snackbar text for [notice].
  String noticeText(YourHisaabNotice notice) => switch (notice) {
        BackedUpNotice(:final Option<String> fileName) =>
          fileName.match(() => _strings.backUpDoneNoName, _strings.backUpDone),
        BackUpFailedNotice() => _strings.backUpFailed,
        BackUpReadFailedNotice() => _strings.backUpReadFailed,
        NotABackupNotice() => _strings.restoreNotBackup,
        BrokenBackupNotice() => _strings.restoreBroken,
        NewerBackupNotice() => _strings.restoreNewer,
        OpenFailedNotice() => _strings.restoreOpenFailed,
        RestoredNotice(:final CalendarDate madeOn) => _strings.restoreDone(backupDay(madeOn)),
        RestoreFailedNotice() => _strings.restoreFailed,
        UndoneNotice() => _strings.restoreUndone,
        UndoFailedNotice() => _strings.restoreUndoFailed,
      };
}
