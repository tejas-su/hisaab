import 'package:expense_tracker/backup/backup.dart';
import 'package:expense_tracker/backup/presentation/bloc/delete_everything_event.dart';
import 'package:expense_tracker/backup/presentation/bloc/delete_everything_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  group('backup states, events and values compare by value', () {
    test('events and stateless states are equal to themselves', () {
      expect(const YourHisaabLoadRequested(), const YourHisaabLoadRequested());
      expect(const YourHisaabLoadRequested().props, isEmpty);
      expect(const DeleteEverythingConfirmed().props, isEmpty);
      expect(const YourHisaabLoading().props, isEmpty);
      expect(const DeleteEverythingWorking().props, isEmpty);
      expect(const DeleteEverythingDone(), const DeleteEverythingDone());
    });

    test('notices compare by their fields', () {
      expect(const NotABackupNotice().props, isEmpty);
      expect(const NotABackupNotice(), isNot(const NewerBackupNotice()));
      expect(const BackedUpNotice(Option<String>.of('a.json')), isNot(const BackedUpNotice(Option<String>.none())));
    });

    test('a saved backup compares by its file name', () {
      expect(const BackedUp(fileName: Option<String>.of('a.json')), const BackedUp(fileName: Option<String>.of('a.json')));
      expect(const BackedUp(fileName: Option<String>.of('a.json')).props, <Object?>[const Option<String>.of('a.json')]);
    });
  });
}
