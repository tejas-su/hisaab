import 'package:equatable/equatable.dart';

/// What moves the *Your hisaab* group (SPEC FR-SE-4) or onboarding's *Restore a backup* chip.
sealed class YourHisaabEvent extends Equatable {
  const YourHisaabEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The group appeared, or the data under it changed; read the last-backup day and undo.
final class YourHisaabLoadRequested extends YourHisaabEvent {
  const YourHisaabLoadRequested();
}

/// A request that reads or writes a file or the data. They share one droppable group, so a tap
/// while one is running is dropped.
sealed class YourHisaabWriteEvent extends YourHisaabEvent {
  const YourHisaabWriteEvent();
}

/// *Back up* (or *Back up first*) was tapped.
final class YourHisaabBackUpRequested extends YourHisaabWriteEvent {
  const YourHisaabBackUpRequested();
}

/// *Restore* (or *Restore a backup*) was tapped; open the file picker.
final class YourHisaabRestoreRequested extends YourHisaabWriteEvent {
  const YourHisaabRestoreRequested();
}

/// *Replace* was tapped in the restore dialog.
final class YourHisaabRestoreConfirmed extends YourHisaabWriteEvent {
  const YourHisaabRestoreConfirmed();
}

/// *Undo* (on the snackbar or the *Undo restore* row) was tapped.
final class YourHisaabUndoRequested extends YourHisaabWriteEvent {
  const YourHisaabUndoRequested();
}

/// *Keep what's here* was tapped, or the dialog was dismissed; nothing changes.
final class YourHisaabRestoreDismissed extends YourHisaabEvent {
  const YourHisaabRestoreDismissed();
}
