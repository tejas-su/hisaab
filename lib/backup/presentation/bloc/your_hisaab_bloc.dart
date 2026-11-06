import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../domain/backup_failures.dart';
import '../../domain/entities/backup_file.dart';
import '../../domain/entities/backup_status.dart';
import '../../domain/repository/backup_repository.dart';
import 'your_hisaab_event.dart';
import 'your_hisaab_state.dart';

/// Owns the *Your hisaab* group: the last-backup line, *Back up*, *Restore* with its dialog, and
/// *Undo restore* (SPEC FR-SE-4, BR-16). Also drives onboarding's *Restore a backup* chip, where
/// [fromOnboarding] restores at once, without the dialog or an undo.
class YourHisaabBloc extends Bloc<YourHisaabEvent, YourHisaabState> {
  YourHisaabBloc({
    required this._backups,
    required this._clock,
    required this._haptics,
    this.fromOnboarding = false,
  }) : super(const YourHisaabLoading()) {
    // why: the newest read wins, so a slow read can't land a stale last-backup day.
    on<YourHisaabLoadRequested>((YourHisaabLoadRequested _, Emitter<YourHisaabState> emit) => _load(emit), transformer: restartable());
    // why: one droppable group, so a second tap, or Back up during a restore, is dropped.
    on<YourHisaabWriteEvent>(_onWrite, transformer: droppable());
    on<YourHisaabRestoreDismissed>(_onRestoreDismissed);
  }

  final BackupRepository _backups;
  final Clock _clock;
  final Haptics _haptics;

  /// Restoring from onboarding: no dialog and no undo, since nothing is there to replace (BR-16).
  final bool fromOnboarding;

  static const BackupStatus _unknown = BackupStatus(lastBackedUp: Option<CalendarDate>.none(), undo: Option<RestoreUndo>.none());

  YourHisaabReady get _ready => switch (state) {
        final YourHisaabReady ready => ready,
        YourHisaabLoading() => const YourHisaabReady(status: _unknown),
      };

  Future<void> _load(Emitter<YourHisaabState> emit) async {
    final Either<Failure, BackupStatus> status = await _backups.status(_clock.today()).run();
    final YourHisaabReady ready = _ready;
    emit(
      YourHisaabReady(
        status: status.getOrElse((Failure failure) {
          _log('your_hisaab.status_failed', failure);
          return ready.status;
        }),
        busy: ready.busy,
        pending: ready.pending,
        notice: ready.notice,
        noticeCount: ready.noticeCount,
      ),
    );
  }

  Future<void> _onWrite(YourHisaabWriteEvent event, Emitter<YourHisaabState> emit) => switch (event) {
        YourHisaabBackUpRequested() => _backUp(emit),
        YourHisaabRestoreRequested() => _pick(emit),
        YourHisaabRestoreConfirmed() => _restore(emit),
        YourHisaabUndoRequested() => _undo(emit),
      };

  Future<void> _backUp(Emitter<YourHisaabState> emit) async {
    emit(_ready.busyWith(YourHisaabBusy.backingUp));
    final Either<Failure, Option<BackedUp>> saved = await _backups.backUp(_clock.today()).run();
    await saved.match(
      (Failure failure) => _fail(emit, failure is BackupWriteFailure ? const BackUpFailedNotice() : const BackUpReadFailedNotice(), failure),
      (Option<BackedUp> done) => done.match(
        () async => emit(_ready.busyWith(YourHisaabBusy.none)),
        (BackedUp file) async {
          await _haptics.success();
          await _settle(emit, BackedUpNotice(file.fileName));
        },
      ),
    );
  }

  Future<void> _pick(Emitter<YourHisaabState> emit) async {
    emit(_ready.busyWith(YourHisaabBusy.checking));
    final Either<Failure, Option<BackupFile>> picked = await _backups.pick().run();
    await picked.match(
      (Failure failure) => _fail(emit, _pickNotice(failure), failure),
      (Option<BackupFile> file) => file.match(
        () async => emit(_ready.busyWith(YourHisaabBusy.none)),
        (BackupFile backup) => fromOnboarding ? _replace(emit, backup) : _ask(emit, backup),
      ),
    );
  }

  Future<void> _ask(Emitter<YourHisaabState> emit, BackupFile file) async {
    final int here = (await _backups.entryCount().run()).getOrElse((Failure _) => 0);
    final YourHisaabReady ready = _ready;
    emit(
      YourHisaabReady(
        status: ready.status,
        pending: Option<PendingRestore>.of(PendingRestore(file: file, entriesHere: here)),
        notice: ready.notice,
        noticeCount: ready.noticeCount,
      ),
    );
  }

  Future<void> _restore(Emitter<YourHisaabState> emit) async {
    final Option<PendingRestore> pending = _ready.pending;
    await pending.match(() async {}, (PendingRestore restore) => _replace(emit, restore.file));
  }

  Future<void> _replace(Emitter<YourHisaabState> emit, BackupFile file) async {
    emit(_ready.busyWith(YourHisaabBusy.restoring));
    final Either<Failure, Unit> done = await _backups.restore(file, at: _clock.now(), keepUndo: !fromOnboarding).run();
    await done.match(
      (Failure failure) => _fail(emit, const RestoreFailedNotice(), failure),
      (Unit _) async {
        await _haptics.success();
        await _settle(emit, RestoredNotice(file.madeOn));
      },
    );
  }

  Future<void> _undo(Emitter<YourHisaabState> emit) async {
    emit(_ready.busyWith(YourHisaabBusy.undoing));
    final Either<Failure, Unit> done = await _backups.undoRestore().run();
    await done.match(
      (Failure failure) => _fail(emit, const UndoFailedNotice(), failure),
      (Unit _) => _settle(emit, const UndoneNotice()),
    );
  }

  void _onRestoreDismissed(YourHisaabRestoreDismissed event, Emitter<YourHisaabState> emit) {
    final YourHisaabReady ready = _ready;
    emit(YourHisaabReady(status: ready.status, notice: ready.notice, noticeCount: ready.noticeCount));
  }

  /// Ends a request with [notice] and fresh status, closing the dialog.
  Future<void> _settle(Emitter<YourHisaabState> emit, YourHisaabNotice notice) async {
    final YourHisaabReady ready = _ready;
    emit(YourHisaabReady(status: ready.status, notice: Option<YourHisaabNotice>.of(notice), noticeCount: ready.noticeCount + 1));
    await _load(emit);
  }

  Future<void> _fail(Emitter<YourHisaabState> emit, YourHisaabNotice notice, Failure failure) async {
    _log('your_hisaab.failed', failure);
    await _haptics.reject();
    await _settle(emit, notice);
  }

  static YourHisaabNotice _pickNotice(Failure failure) => switch (failure) {
        NotABackupFailure() => const NotABackupNotice(),
        NewerBackupFailure() => const NewerBackupNotice(),
        BrokenBackupFailure() => const BrokenBackupNotice(),
        _ => const OpenFailedNotice(),
      };

  // why: only the failure's type is logged; its message may quote file contents.
  static void _log(String tag, Failure failure) =>
      AppLogger.log(tag: tag, data: <String, Object?>{'type': failure.runtimeType.toString()});
}
