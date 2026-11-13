import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/presentation/bloc/bill_sheet_state.dart';
import 'package:hisaab/settings/presentation/bloc/bills_event.dart';
import 'package:hisaab/settings/presentation/bloc/used_event.dart';
import 'package:hisaab/settings/presentation/bloc/used_state.dart';

import '../../../helpers/fixtures/ledger/worked_example.dart';

Entry get _entry => Entry(
      id: 900,
      amount: Money.fromMajor(4000),
      kind: EntryKind.used,
      categoryId: 11,
      date: WorkedExample.today,
      createdAt: WorkedExample.now,
      savingId: 5,
    );

void main() {
  group('UsedState', () {
    UsedReady ready({int setAside = 12000, int rupees = 0}) =>
        UsedReady(saving: WorkedExample.insurance, setAsideRupees: setAside, rupees: rupees);

    test('compares by its fields', () {
      expect(ready(), ready());
      expect(ready(rupees: 5), isNot(ready()));
      expect(ready().copyWith(rupees: 5), ready(rupees: 5));
      expect(const UsedLoading().props, isEmpty);
      expect(UsedFailed(DatabaseFailure('x')).props, hasLength(1));
      expect(UsedDone(UsedOutcome(entry: _entry, saving: WorkedExample.insurance)).props, hasLength(1));
    });

    test('allSelected needs something typed that equals what is set aside', () {
      expect(ready(rupees: 12000).allSelected, isTrue);
      expect(ready(rupees: 11999).allSelected, isFalse);
      expect(ready(setAside: 0).allSelected, isFalse);
    });

    test('canSave needs an amount within what is set aside and no write in flight', () {
      expect(ready().canSave, isFalse);
      expect(ready(rupees: 12000).canSave, isTrue);
      expect(ready(rupees: 12001).canSave, isFalse);
      expect(ready(rupees: 5).copyWith(writing: true).canSave, isFalse);
    });

    test('nothingToUse is true under one rupee set aside', () {
      expect(ready(setAside: 0).nothingToUse, isTrue);
      expect(ready(setAside: 1).nothingToUse, isFalse);
    });

    test('copyWith resets saveFailed unless passed', () {
      expect(ready().copyWith(saveFailed: true).copyWith(rupees: 1).saveFailed, isFalse);
    });
  });

  group('UsedEvent', () {
    test('events compare by their fields', () {
      expect(UsedLoadRequested(WorkedExample.insurance).props, <Object?>[WorkedExample.insurance]);
      expect(const UsedKeyPressed('5').props, <Object?>['5']);
      expect(const UsedBackspacePressed().props, isEmpty);
      expect(const UsedCleared().props, isEmpty);
      expect(const UsedAllPressed().props, isEmpty);
      expect(const UsedSavePressed().props, isEmpty);
      expect(const UsedReset().props, isEmpty);
    });
  });

  group('outcomes and the events that carry them', () {
    test('compare by their fields', () {
      final UsedOutcome outcome = UsedOutcome(entry: _entry, saving: WorkedExample.insurance);

      expect(outcome, UsedOutcome(entry: _entry, saving: WorkedExample.insurance));
      expect(BillSheetUsed(outcome).props, <Object?>[outcome]);
      expect(BillsUsedDone(outcome).props, <Object?>[outcome]);
      expect(BillsUsedUndoRequested(_entry).props, <Object?>[_entry]);
    });
  });
}
