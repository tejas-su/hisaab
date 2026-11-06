import 'dart:async';

import 'package:expense_tracker/backup/domain/usecase/delete_everything.dart';
import 'package:expense_tracker/backup/presentation/bloc/delete_everything_bloc.dart';
import 'package:expense_tracker/backup/presentation/bloc/delete_everything_event.dart';
import 'package:expense_tracker/backup/presentation/bloc/delete_everything_state.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_backup_repository.dart';
import '../../../helpers/fakes/fake_bill_reminders.dart';
import '../../../helpers/fakes/fake_haptics.dart';

void main() {
  late FakeBackupRepository backups;
  late FakeHaptics haptics;
  late DeleteEverythingBloc bloc;

  setUp(() {
    backups = FakeBackupRepository();
    haptics = FakeHaptics();
    bloc = DeleteEverythingBloc(
      deleteEverything: DeleteEverything(backups: backups, reminders: FakeBillReminders()),
      haptics: haptics,
    );
    addTearDown(bloc.close);
  });

  group('DeleteEverythingBloc (FR-SE-4 AC-8)', () {
    test('starts idle', () {
      expect(bloc.state, const DeleteEverythingIdle());
    });

    test('emits [Working, Done] when the delete succeeds', () async {
      final Future<void> expectation =
          expectLater(bloc.stream, emitsInOrder(<Matcher>[isA<DeleteEverythingWorking>(), isA<DeleteEverythingDone>()]));

      await bloc.dispatch(const DeleteEverythingConfirmed());

      await expectation;
      expect(backups.wipes, 1);
    });

    test('a failed delete goes back to idle, counting the failure, with a reject', () async {
      backups.writeAnswer = Either<Failure, Unit>.left(DatabaseFailure('x'));

      await bloc.dispatch(const DeleteEverythingConfirmed());
      await bloc.dispatch(const DeleteEverythingConfirmed());

      expect(bloc.state, const DeleteEverythingIdle(failures: 2));
      expect(haptics.events, <String>['reject', 'reject']);
    });

    test('a second confirm while deleting is dropped', () async {
      backups.gate = Completer<void>();

      bloc
        ..add(const DeleteEverythingConfirmed())
        ..add(const DeleteEverythingConfirmed());
      await pumpEventQueue();
      backups.gate!.complete();
      await pumpEventQueue();

      expect(backups.wipes, 1);
    });
  });
}
