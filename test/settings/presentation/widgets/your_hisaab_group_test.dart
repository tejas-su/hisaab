import 'dart:async';

import 'package:expense_tracker/backup/backup.dart';
import 'package:expense_tracker/backup/domain/backup_failures.dart';
import 'package:expense_tracker/backup/domain/entities/backup_file.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/widgets/hisaab_snackbar_host.dart';
import 'package:expense_tracker/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_backup_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/pump_app.dart';

const CalendarDate _today = CalendarDate(2026, 11, 6);

void main() {
  late FakeBackupRepository backups;
  late int replaced;
  late int deleteOpened;

  setUp(() {
    backups = FakeBackupRepository();
    replaced = 0;
    deleteOpened = 0;
  });

  Future<YourHisaabBloc> pumpGroup(WidgetTester tester, {Size size = TestWindows.phone, double textScale = 1}) async {
    final YourHisaabBloc bloc = await tester.buildBloc(
      () => YourHisaabBloc(backups: backups, clock: FakeClock(DateTime(2026, 11, 6, 10)), haptics: FakeHaptics()),
    );
    addTearDown(bloc.close);
    await pumpApp(
      tester,
      Scaffold(
        body: HisaabSnackbarHost(
          child: BlocProvider<YourHisaabBloc>.value(
            value: bloc,
            child: YourHisaabNotices(
              onDataReplaced: () => replaced++,
              child: ListView(
                children: <Widget>[YourHisaabGroup(today: _today, onOpenDelete: () => deleteOpened++)],
              ),
            ),
          ),
        ),
      ),
      size: size,
      textScale: textScale,
    );
    bloc.add(const YourHisaabLoadRequested());
    await tester.settle();
    return bloc;
  }

  group('YourHisaabGroup (FR-SE-4)', () {
    testWidgets('shows the rows, their second lines and the no-password note', (WidgetTester tester) async {
      await pumpGroup(tester);

      expect(find.text('Back up'), findsOneWidget);
      expect(find.text('Not backed up yet'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
      expect(find.text('Bring back from a backup file'), findsOneWidget);
      expect(find.text('Delete everything'), findsOneWidget);
      expect(find.text('Clear it all and start again'), findsOneWidget);
      expect(find.textContaining('has no password'), findsOneWidget);
      expect(find.text('Undo restore'), findsNothing);
    });

    testWidgets('says when the last backup was made', (WidgetTester tester) async {
      backups.statusAnswer = Either<Failure, BackupStatus>.right(
        const BackupStatus(lastBackedUp: Option<CalendarDate>.of(CalendarDate(2026, 10, 12)), undo: Option<RestoreUndo>.none()),
      );

      await pumpGroup(tester);

      expect(find.text('Last backed up 12 Oct'), findsOneWidget);
    });

    testWidgets('says Backed up today on the day', (WidgetTester tester) async {
      backups.statusAnswer = Either<Failure, BackupStatus>.right(
        const BackupStatus(lastBackedUp: Option<CalendarDate>.of(_today), undo: Option<RestoreUndo>.none()),
      );

      await pumpGroup(tester);

      expect(find.text('Backed up today'), findsOneWidget);
    });

    testWidgets('Back up reads Backing up while it runs, then names the file', (WidgetTester tester) async {
      backups.gate = Completer<void>();
      await pumpGroup(tester);

      await tester.tap(find.byKey(const ValueKey<String>('back-up')));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(find.text('Backing up…'), findsOneWidget);

      backups.gate!.complete();
      await tester.settle();
      expect(find.text('Backed up as hisaab-backup-2026-11-06.json'), findsOneWidget);
      expect(replaced, 0);
    });

    testWidgets('Restore opens the one dialog with the facts, and Replace restores with Undo (BR-16)',
        (WidgetTester tester) async {
      await pumpGroup(tester);

      await tester.tap(find.byKey(const ValueKey<String>('restore')));
      await tester.settle();
      expect(find.text('Replace with this backup?'), findsOneWidget);
      expect(find.textContaining('Made on 12 Oct, with 214 entries.'), findsOneWidget);
      expect(find.textContaining('including 37 entries'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('restore-replace')));
      await tester.settle();
      expect(find.text('Replace with this backup?'), findsNothing);
      expect(backups.restores.single.$2, isTrue);
      expect(find.text('Backup from 12 Oct restored'), findsOneWidget);
      expect(replaced, 1);

      await tester.tap(find.text('Undo'));
      await tester.settle();
      expect(backups.undos, 1);
      expect(replaced, 2);
    });

    testWidgets("Keep what's here closes the dialog and changes nothing", (WidgetTester tester) async {
      await pumpGroup(tester);
      await tester.tap(find.byKey(const ValueKey<String>('restore')));
      await tester.settle();

      await tester.tap(find.byKey(const ValueKey<String>('restore-keep')));
      await tester.settle();

      expect(find.text('Replace with this backup?'), findsNothing);
      expect(backups.restores, isEmpty);
      expect(find.text('Restore'), findsOneWidget);
    });

    testWidgets('the dialog reads Bringing back while it restores', (WidgetTester tester) async {
      backups.gate = Completer<void>();
      await pumpGroup(tester);
      await tester.tap(find.byKey(const ValueKey<String>('restore')));
      await tester.settle();

      await tester.tap(find.byKey(const ValueKey<String>('restore-replace')));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(find.text('Bringing back your hisaab…'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('restore-keep')), findsNothing);
      backups.gate!.complete();
      await tester.settle();
    });

    testWidgets('a file that is not a backup says so, without a dialog', (WidgetTester tester) async {
      backups.pickAnswer = Either<Failure, Option<BackupFile>>.left(const NotABackupFailure('x'));
      await pumpGroup(tester);

      await tester.tap(find.byKey(const ValueKey<String>('restore')));
      await tester.settle();

      expect(find.textContaining("That's not a hisaab backup."), findsOneWidget);
      expect(find.text('Replace with this backup?'), findsNothing);
    });

    testWidgets('Undo restore shows for the restore day and undoes (E42)', (WidgetTester tester) async {
      backups.statusAnswer = Either<Failure, BackupStatus>.right(
        const BackupStatus(
          lastBackedUp: Option<CalendarDate>.none(),
          undo: Option<RestoreUndo>.of(RestoreUndo(restoredOn: CalendarDate(2026, 11, 5), addedSince: 0)),
        ),
      );
      await pumpGroup(tester);

      expect(find.text('Undo restore'), findsOneWidget);
      expect(find.text('Go back to what you had before 5 Nov'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('undo-restore')));
      await tester.settle();
      expect(backups.undos, 1);
      expect(find.text('Back to what you had before'), findsOneWidget);
    });

    testWidgets('a failed undo says the backup is still in use', (WidgetTester tester) async {
      backups
        ..statusAnswer = Either<Failure, BackupStatus>.right(
          const BackupStatus(
            lastBackedUp: Option<CalendarDate>.none(),
            undo: Option<RestoreUndo>.of(RestoreUndo(restoredOn: CalendarDate(2026, 11, 5), addedSince: 0)),
          ),
        )
        ..writeAnswer = Either<Failure, Unit>.left(DatabaseFailure('x'));
      await pumpGroup(tester);

      await tester.tap(find.byKey(const ValueKey<String>('undo-restore')));
      await tester.settle();

      expect(find.text("Couldn't go back. The backup is still in use."), findsOneWidget);
      expect(replaced, 0);
    });

    testWidgets('system Back closes the restore dialog and changes nothing', (WidgetTester tester) async {
      await pumpGroup(tester);
      await tester.tap(find.byKey(const ValueKey<String>('restore')));
      await tester.settle();

      await tester.binding.handlePopRoute();
      await tester.settle();

      expect(find.text('Replace with this backup?'), findsNothing);
      expect(backups.restores, isEmpty);
    });

    testWidgets('Undo restore says how many new entries would go', (WidgetTester tester) async {
      backups.statusAnswer = Either<Failure, BackupStatus>.right(
        const BackupStatus(
          lastBackedUp: Option<CalendarDate>.none(),
          undo: Option<RestoreUndo>.of(RestoreUndo(restoredOn: CalendarDate(2026, 11, 5), addedSince: 3)),
        ),
      );

      await pumpGroup(tester);

      expect(find.text('The 3 entries added since will go.'), findsOneWidget);
    });

    testWidgets('Delete everything opens its page', (WidgetTester tester) async {
      await pumpGroup(tester);

      await tester.tap(find.byKey(const ValueKey<String>('open-delete-everything')));

      expect(deleteOpened, 1);
    });

    testWidgets('lays out on a 320dp phone at 2× text', (WidgetTester tester) async {
      await pumpGroup(tester, size: TestWindows.smallPhone, textScale: 2);

      expect(tester.takeException(), isNull);
    });

    testWidgets('the restore dialog fits a 320dp phone at 2× text', (WidgetTester tester) async {
      await pumpGroup(tester, size: TestWindows.smallPhone, textScale: 2);

      await tester.tap(find.byKey(const ValueKey<String>('restore')));
      await tester.settle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey<String>('restore-replace')), findsOneWidget);
    });
  });
}
