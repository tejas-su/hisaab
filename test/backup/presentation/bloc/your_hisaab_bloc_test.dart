import 'dart:async';

import 'package:expense_tracker/backup/domain/backup_failures.dart';
import 'package:expense_tracker/backup/domain/entities/backup_file.dart';
import 'package:expense_tracker/backup/domain/entities/backup_status.dart';
import 'package:expense_tracker/backup/presentation/bloc/your_hisaab_bloc.dart';
import 'package:expense_tracker/backup/presentation/bloc/your_hisaab_event.dart';
import 'package:expense_tracker/backup/presentation/bloc/your_hisaab_state.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_backup_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';

void main() {
  late FakeBackupRepository backups;
  late FakeHaptics haptics;

  YourHisaabBloc build({bool fromOnboarding = false}) {
    final YourHisaabBloc bloc = YourHisaabBloc(
      backups: backups,
      clock: FakeClock(DateTime(2026, 11, 6, 10)),
      haptics: haptics,
      fromOnboarding: fromOnboarding,
    );
    addTearDown(bloc.close);
    return bloc;
  }

  YourHisaabReady ready(YourHisaabBloc bloc) => bloc.state as YourHisaabReady;

  setUp(() {
    backups = FakeBackupRepository();
    haptics = FakeHaptics();
  });

  group('YourHisaabBloc', () {
    test('starts loading', () {
      expect(build().state, const YourHisaabLoading());
    });

    group('load', () {
      test('shows the last-backup day and the undo', () async {
        const BackupStatus status = BackupStatus(
          lastBackedUp: Option<CalendarDate>.of(CalendarDate(2026, 10, 12)),
          undo: Option<RestoreUndo>.of(RestoreUndo(restoredOn: CalendarDate(2026, 11, 5), addedSince: 3)),
        );
        backups.statusAnswer = Either<Failure, BackupStatus>.right(status);
        final YourHisaabBloc bloc = build();

        await bloc.dispatch(const YourHisaabLoadRequested());

        expect(bloc.state, const YourHisaabReady(status: status));
      });

      test('a failed read still lets the rows act, as never backed up', () async {
        backups.statusAnswer = Either<Failure, BackupStatus>.left(const InvalidDataFailure('x'));
        final YourHisaabBloc bloc = build();

        await bloc.dispatch(const YourHisaabLoadRequested());

        expect(ready(bloc).status.lastBackedUp, const Option<CalendarDate>.none());
      });
    });

    group('back up (FR-SE-4 AC-2)', () {
      test('shows Backing up, then the file name, then the fresh day', () async {
        final YourHisaabBloc bloc = build();
        final Future<void> expectation = expectLater(
          bloc.stream,
          emitsInOrder(<Matcher>[
            isA<YourHisaabReady>().having((YourHisaabReady s) => s.busy, 'busy', YourHisaabBusy.backingUp),
            isA<YourHisaabReady>()
                .having((YourHisaabReady s) => s.notice, 'notice', const Option<YourHisaabNotice>.of(BackedUpNotice(Option<String>.of('hisaab-backup-2026-11-06.json'))))
                .having((YourHisaabReady s) => s.busy, 'busy', YourHisaabBusy.none),
          ]),
        );

        await bloc.dispatch(const YourHisaabBackUpRequested());

        await expectation;
        expect(haptics.events, <String>['success']);
        expect(ready(bloc).noticeCount, 1);
      });

      test('a cancelled Save to screen ends quietly (E35)', () async {
        backups.backUpAnswer = Either<Failure, Option<BackedUp>>.right(const Option<BackedUp>.none());
        final YourHisaabBloc bloc = build();

        await bloc.dispatch(const YourHisaabBackUpRequested());

        expect(ready(bloc).busy, YourHisaabBusy.none);
        expect(ready(bloc).notice, const Option<YourHisaabNotice>.none());
        expect(haptics.events, isEmpty);
      });

      test('a failed write says so (E36)', () async {
        backups.backUpAnswer = Either<Failure, Option<BackedUp>>.left(const BackupWriteFailure('full'));
        final YourHisaabBloc bloc = build();

        await bloc.dispatch(const YourHisaabBackUpRequested());

        expect(ready(bloc).notice, const Option<YourHisaabNotice>.of(BackUpFailedNotice()));
        expect(haptics.events, <String>['reject']);
      });

      test('a failed read of hisaab itself says nothing changed', () async {
        backups.backUpAnswer = Either<Failure, Option<BackedUp>>.left(DatabaseFailure('locked'));
        final YourHisaabBloc bloc = build();

        await bloc.dispatch(const YourHisaabBackUpRequested());

        expect(ready(bloc).notice, const Option<YourHisaabNotice>.of(BackUpReadFailedNotice()));
      });

      test('a second tap while backing up is dropped', () async {
        backups.gate = Completer<void>();
        final YourHisaabBloc bloc = build();

        bloc
          ..add(const YourHisaabBackUpRequested())
          ..add(const YourHisaabBackUpRequested());
        await pumpEventQueue();
        backups.gate!.complete();
        await pumpEventQueue();

        expect(backups.backUps, 1);
      });
    });

    group('restore from Settings (BR-16)', () {
      test('a checked file waits for the dialog with both counts', () async {
        final YourHisaabBloc bloc = build();

        await bloc.dispatch(const YourHisaabRestoreRequested());

        expect(ready(bloc).pending, const Option<PendingRestore>.of(PendingRestore(file: fakeBackupFile, entriesHere: 37)));
        expect(ready(bloc).busy, YourHisaabBusy.none);
        expect(backups.restores, isEmpty);
      });

      test('an unreadable count here reads as none', () async {
        backups.entryCountAnswer = Either<Failure, int>.left(const InvalidDataFailure('x'));
        final YourHisaabBloc bloc = build();

        await bloc.dispatch(const YourHisaabRestoreRequested());

        expect(ready(bloc).pending.toNullable()?.entriesHere, 0);
      });

      test('Replace restores with an undo, then says so', () async {
        final YourHisaabBloc bloc = build();
        await bloc.dispatch(const YourHisaabRestoreRequested());

        await bloc.dispatch(const YourHisaabRestoreConfirmed());

        expect(backups.restores, <(BackupFile, bool)>[(fakeBackupFile, true)]);
        expect(ready(bloc).pending, const Option<PendingRestore>.none());
        expect(ready(bloc).notice, const Option<YourHisaabNotice>.of(RestoredNotice(CalendarDate(2026, 10, 12))));
        expect(ready(bloc).notice.toNullable()?.replacedData, isTrue);
        expect(haptics.events, <String>['success']);
      });

      test('Replace shows the dialog busy while it runs', () async {
        backups.gate = Completer<void>();
        final YourHisaabBloc bloc = build();
        await bloc.dispatch(const YourHisaabRestoreRequested());

        await bloc.dispatch(const YourHisaabRestoreConfirmed());

        expect(ready(bloc).busy, YourHisaabBusy.restoring);
        expect(ready(bloc).pending.isSome(), isTrue);
        backups.gate!.complete();
      });

      test("Keep what's here changes nothing", () async {
        final YourHisaabBloc bloc = build();
        await bloc.dispatch(const YourHisaabRestoreRequested());

        await bloc.dispatch(const YourHisaabRestoreDismissed());

        expect(ready(bloc).pending, const Option<PendingRestore>.none());
        expect(backups.restores, isEmpty);
      });

      test('a confirm with no checked file does nothing', () async {
        final YourHisaabBloc bloc = build();
        await bloc.dispatch(const YourHisaabLoadRequested());

        await bloc.dispatch(const YourHisaabRestoreConfirmed());

        expect(backups.restores, isEmpty);
      });

      test('a failed replace says nothing changed', () async {
        backups.writeAnswer = Either<Failure, Unit>.left(DatabaseFailure('x'));
        final YourHisaabBloc bloc = build();
        await bloc.dispatch(const YourHisaabRestoreRequested());

        await bloc.dispatch(const YourHisaabRestoreConfirmed());

        expect(ready(bloc).notice, const Option<YourHisaabNotice>.of(RestoreFailedNotice()));
        expect(ready(bloc).notice.toNullable()?.replacedData, isFalse);
      });

      test('a cancelled pick ends quietly', () async {
        backups.pickAnswer = Either<Failure, Option<BackupFile>>.right(const Option<BackupFile>.none());
        final YourHisaabBloc bloc = build();

        await bloc.dispatch(const YourHisaabRestoreRequested());

        expect(ready(bloc).busy, YourHisaabBusy.none);
        expect(ready(bloc).notice, const Option<YourHisaabNotice>.none());
      });

      final List<(Failure, YourHisaabNotice)> refusals = <(Failure, YourHisaabNotice)>[
        (const NotABackupFailure('x'), const NotABackupNotice()),
        (const NewerBackupFailure('x'), const NewerBackupNotice()),
        (const BrokenBackupFailure('x'), const BrokenBackupNotice()),
        (const BackupOpenFailure('x'), const OpenFailedNotice()),
        (DatabaseFailure('x'), const OpenFailedNotice()),
      ];
      for (final (Failure failure, YourHisaabNotice notice) in refusals) {
        test('a ${failure.runtimeType} shows ${notice.runtimeType} and changes nothing (E14)', () async {
          backups.pickAnswer = Either<Failure, Option<BackupFile>>.left(failure);
          final YourHisaabBloc bloc = build();

          await bloc.dispatch(const YourHisaabRestoreRequested());

          expect(ready(bloc).notice, Option<YourHisaabNotice>.of(notice));
          expect(backups.restores, isEmpty);
          expect(haptics.events, <String>['reject']);
        });
      }
    });

    test('from onboarding a checked file restores at once, without an undo', () async {
      final YourHisaabBloc bloc = build(fromOnboarding: true);

      await bloc.dispatch(const YourHisaabRestoreRequested());

      expect(backups.restores, <(BackupFile, bool)>[(fakeBackupFile, false)]);
      expect(ready(bloc).notice, const Option<YourHisaabNotice>.of(RestoredNotice(CalendarDate(2026, 10, 12))));
    });

    group('undo restore (E42)', () {
      test('puts the old data back and says so', () async {
        final YourHisaabBloc bloc = build();

        await bloc.dispatch(const YourHisaabUndoRequested());

        expect(backups.undos, 1);
        expect(ready(bloc).notice, const Option<YourHisaabNotice>.of(UndoneNotice()));
        expect(ready(bloc).notice.toNullable()?.replacedData, isTrue);
      });

      test('a failed undo says the backup is still in use', () async {
        backups.writeAnswer = Either<Failure, Unit>.left(DatabaseFailure('x'));
        final YourHisaabBloc bloc = build();

        await bloc.dispatch(const YourHisaabUndoRequested());

        expect(ready(bloc).notice, const Option<YourHisaabNotice>.of(UndoFailedNotice()));
      });
    });

    test('closing mid-request does not throw', () async {
      backups.gate = Completer<void>();
      final YourHisaabBloc bloc = build()..add(const YourHisaabBackUpRequested());
      await pumpEventQueue();

      final Future<void> closed = bloc.close();
      backups.gate!.complete();

      await expectLater(closed, completes);
    });
  });
}
