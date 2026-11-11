import 'package:hisaab/backup/domain/usecase/delete_everything.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/notifications/bill_reminder.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fakes/fake_backup_repository.dart';
import '../../../helpers/fakes/fake_bill_reminders.dart';

void main() {
  late FakeBackupRepository backups;
  late FakeBillReminders reminders;
  late DeleteEverything deleteEverything;

  setUp(() {
    backups = FakeBackupRepository();
    reminders = FakeBillReminders();
    deleteEverything = DeleteEverything(backups: backups, reminders: reminders);
  });

  group('DeleteEverything (FR-SE-4 AC-8)', () {
    test('wipes the data, then removes every reminder', () async {
      final Either<Failure, Unit> result = await deleteEverything(const NoParams()).run();

      expect(result, Either<Failure, Unit>.right(unit));
      expect(backups.wipes, 1);
      expect(reminders.arms, 1);
      expect(reminders.scheduled, isEmpty);
      expect(reminders.kept, isEmpty);
    });

    test('a failed wipe keeps the reminders and returns the failure', () async {
      backups.writeAnswer = Either<Failure, Unit>.left(const InvalidDataFailure('locked'));

      final Either<Failure, Unit> result = await deleteEverything(const NoParams()).run();

      expect(result.getLeft().toNullable(), isA<InvalidDataFailure>());
      expect(reminders.arms, 0);
      expect(reminders.scheduled, const <BillReminder>[]);
    });
  });
}
