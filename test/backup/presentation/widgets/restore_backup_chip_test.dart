import 'package:expense_tracker/backup/backup.dart';
import 'package:expense_tracker/backup/domain/backup_failures.dart';
import 'package:expense_tracker/backup/domain/entities/backup_file.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/widgets/hisaab_snackbar_host.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_backup_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeBackupRepository backups;
  late int restored;

  setUp(() {
    backups = FakeBackupRepository();
    restored = 0;
  });

  Future<void> pumpChip(WidgetTester tester) async {
    final YourHisaabBloc bloc = await tester.buildBloc(
      () => YourHisaabBloc(
        backups: backups,
        clock: FakeClock(DateTime(2026, 11, 6, 10)),
        haptics: FakeHaptics(),
        fromOnboarding: true,
      ),
    );
    addTearDown(bloc.close);
    await pumpApp(
      tester,
      Scaffold(
        body: HisaabSnackbarHost(
          child: BlocProvider<YourHisaabBloc>.value(
            value: bloc,
            child: Center(child: RestoreBackupChip(onRestored: () => restored++)),
          ),
        ),
      ),
    );
  }

  group('RestoreBackupChip (FR-ON-1)', () {
    testWidgets('a good backup restores at once, without a dialog or undo', (WidgetTester tester) async {
      await pumpChip(tester);
      expect(find.text('Restore a backup'), findsOneWidget);
      expect(find.bySemanticsLabel('Restore a backup from another phone'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey<String>('restore-a-backup')));
      await tester.settle();

      expect(find.text('Replace with this backup?'), findsNothing);
      expect(backups.restores.single.$2, isFalse);
      expect(restored, 1);
    });

    testWidgets('a backup from a newer hisaab says so and stays', (WidgetTester tester) async {
      backups.pickAnswer = Either<Failure, Option<BackupFile>>.left(const NewerBackupFailure('x'));
      await pumpChip(tester);

      await tester.tap(find.byKey(const ValueKey<String>('restore-a-backup')));
      await tester.settle();

      expect(find.textContaining('newer hisaab'), findsOneWidget);
      expect(restored, 0);
    });
  });
}
