import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/presentation/bloc/used_bloc.dart';
import 'package:hisaab/settings/presentation/bloc/used_event.dart';
import 'package:hisaab/settings/presentation/bloc/used_state.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late FakeCategoryRepository categories;
  late FakeHaptics haptics;
  late UsedBloc bloc;

  setUp(() {
    ledger = FakeLedgerRepository(<Entry>[...WorkedExample.entries, ...WorkedExample.insurancePutIns]);
    recurring = FakeRecurringRepository(<RecurringRule>[...WorkedExample.rules, WorkedExample.insurance]);
    categories = FakeCategoryRepository();
    haptics = FakeHaptics();
    bloc = UsedBloc(
      getSetAside: GetSetAside(recurring: recurring, ledger: ledger),
      useFromSavings: UseFromSavings(ledger: ledger, categories: categories, clock: FakeClock(WorkedExample.now)),
      haptics: haptics,
    );
  });

  tearDown(() async {
    await bloc.close();
    await ledger.dispose();
  });

  UsedReady ready() => bloc.state as UsedReady;

  Future<void> load() => bloc.dispatch(UsedLoadRequested(WorkedExample.insurance));

  Future<void> type(String digits) async {
    for (final String digit in digits.split('')) {
      await bloc.dispatch(UsedKeyPressed(digit));
    }
  }

  group('UsedBloc (BR-19, AC-Y6 to AC-Y9)', () {
    test('starts loading', () => expect(bloc.state, const UsedLoading()));

    test('load shows nothing typed and the set-aside from the ledger', () async {
      await load();

      expect(ready().rupees, 0);
      expect(ready().setAsideRupees, 12000);
      expect(ready().saving, WorkedExample.insurance);
      expect(ready().canSave, isFalse);
    });

    test('a failed read is UsedFailed', () async {
      ledger.failure = DatabaseFailure('ledger');

      await load();

      expect(bloc.state, isA<UsedFailed>());
    });

    test('a saving the summary does not list has nothing set aside', () async {
      recurring.rules = WorkedExample.rules;

      await load();

      expect(ready().setAsideRupees, 0);
      expect(ready().nothingToUse, isTrue);
    });

    test('a digit adds to the amount with a tick', () async {
      await load();

      await type('8');

      expect(ready().rupees, 8);
      expect(haptics.events, <String>['tick']);
    });

    test('digits build the amount, 00 appends two zeros, and backspace removes one', () async {
      await load();

      await type('4');
      await bloc.dispatch(const UsedKeyPressed('00'));
      expect(ready().rupees, 400);

      await bloc.dispatch(const UsedBackspacePressed());
      expect(ready().rupees, 40);
    });

    test('typing the whole set-aside is accepted', () async {
      await load();

      await type('12000');

      expect(ready().rupees, 12000);
      expect(ready().allSelected, isTrue);
      expect(ready().capShown, isFalse);
    });

    test('a digit past the set-aside is refused: reject haptic, rejections + 1, capShown, amount unchanged', () async {
      await load();
      await type('1200');

      await type('1');

      expect(ready().rupees, 1200);
      expect(ready().rejections, 1);
      expect(ready().capShown, isTrue);
      expect(haptics.events.last, 'reject');
    });

    test('the cap line clears on the next accepted key', () async {
      await load();
      await type('12001');
      expect(ready().capShown, isTrue);

      await bloc.dispatch(const UsedBackspacePressed());

      expect(ready().capShown, isFalse);
      expect(ready().rupees, 120);
    });

    test('a 10th digit is refused with the same signals', () async {
      ledger.entries.add(Entry(
        id: 400,
        amount: Money.fromMajor(999999999),
        kind: EntryKind.saved,
        categoryId: 11,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
        recurringId: 5,
      ));
      await load();
      await type('999999999');

      await type('9');

      expect(ready().rupees, 999999999);
      expect(ready().rejections, 1);
      expect(ready().capShown, isTrue);
      expect(haptics.events.last, 'reject');
    });

    test('All of it fills the set-aside; a second press clears; the first key afterwards replaces it', () async {
      await load();

      await bloc.dispatch(const UsedAllPressed());
      expect(ready().rupees, 12000);
      expect(ready().allSelected, isTrue);

      await bloc.dispatch(const UsedKeyPressed('5'));
      expect(ready().rupees, 5);
      expect(ready().replaceNext, isFalse);

      await bloc.dispatch(const UsedAllPressed());
      await bloc.dispatch(const UsedAllPressed());
      expect(ready().rupees, 0);
      expect(ready().allSelected, isFalse);
    });

    test('All of it does nothing when nothing is set aside', () async {
      recurring.rules = WorkedExample.rules;
      await load();

      await bloc.dispatch(const UsedAllPressed());

      expect(ready().rupees, 0);
    });

    test('allSelected is true only while the amount equals the set-aside (AC-Y11)', () async {
      await load();

      await bloc.dispatch(const UsedAllPressed());
      expect(ready().allSelected, isTrue);

      await bloc.dispatch(const UsedBackspacePressed());
      expect(ready().allSelected, isFalse);
    });

    test('long-pressing backspace clears the amount', () async {
      await load();
      await type('345');

      await bloc.dispatch(const UsedCleared());

      expect(ready().rupees, 0);
    });

    test('Save with nothing typed does nothing', () async {
      await load();

      await bloc.dispatch(const UsedSavePressed());

      expect(bloc.state, isA<UsedReady>());
      expect(ledger.saved, isEmpty);
    });

    test('Save writes the entry, emits UsedDone with a success haptic', () async {
      await load();
      await type('4000');

      await bloc.dispatch(const UsedSavePressed());

      final UsedDone done = bloc.state as UsedDone;
      expect(done.outcome.entry.amount, Money.fromMajor(4000));
      expect(done.outcome.entry.kind, EntryKind.used);
      expect(done.outcome.entry.savingId, 5);
      expect(done.outcome.saving, WorkedExample.insurance);
      expect(haptics.events.last, 'success');
    });

    test('a double Save writes one entry', () async {
      await load();
      await type('4000');
      final Completer<void> gate = Completer<void>();
      ledger.nextAddGate = gate;

      bloc.add(const UsedSavePressed());
      await pumpEventQueue();
      bloc.add(const UsedSavePressed());
      await pumpEventQueue();
      gate.complete();
      await pumpEventQueue();

      expect(ledger.saved, hasLength(1));
    });

    test('keys are ignored while a save is writing', () async {
      await load();
      await type('4000');
      final Completer<void> gate = Completer<void>();
      ledger.nextAddGate = gate;
      bloc.add(const UsedSavePressed());
      await pumpEventQueue();

      await type('1');
      await bloc.dispatch(const UsedReset());

      expect(ready().rupees, 4000);
      expect(ready().writing, isTrue);
      gate.complete();
      await pumpEventQueue();
    });

    test('a failed write keeps the keypad and digits, saveFailed true, reject haptic', () async {
      await load();
      await type('4000');
      categories.failure = DatabaseFailure('categories');

      await bloc.dispatch(const UsedSavePressed());

      expect(ready().rupees, 4000);
      expect(ready().saveFailed, isTrue);
      expect(ready().writing, isFalse);
      expect(haptics.events.last, 'reject');
    });

    test('a refused write refreshes the set-aside and keeps the sheet (E99)', () async {
      await load();
      await type('9000');
      ledger.entries.removeWhere((Entry e) => e.id >= 105 && e.id <= 111);

      await bloc.dispatch(const UsedSavePressed());

      expect(ready().setAsideRupees, 5000);
      expect(ready().rupees, 9000);
      expect(ready().capShown, isTrue);
      expect(ready().canSave, isFalse);
      expect(ready().writing, isFalse);
      expect(haptics.events.last, 'reject');
    });

    test('the set-aside falling to zero behind the sheet shows nothingToUse and disables Save', () async {
      await load();
      await type('100');
      ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.saved && e.recurringId == 5);

      await bloc.dispatch(const UsedSavePressed());

      expect(ready().nothingToUse, isTrue);
      expect(ready().canSave, isFalse);
    });

    test('a refused write whose refresh also fails keeps the old figure', () async {
      await load();
      await type('9000');
      ledger.entries.removeWhere((Entry e) => e.id >= 105 && e.id <= 111);
      recurring.failure = null;

      await bloc.dispatch(const UsedSavePressed());
      recurring.failure = DatabaseFailure('rules');
      await bloc.dispatch(const UsedSavePressed());

      expect(ready().setAsideRupees, 5000);
    });

    test('a reload restarts: an older slower read does not land last', () async {
      final Completer<void> slow = Completer<void>();
      recurring.nextReadGate = slow;
      bloc.add(UsedLoadRequested(WorkedExample.insurance));
      await pumpEventQueue();
      ledger.entries.removeWhere((Entry e) => e.id >= 105 && e.id <= 111);

      await load();
      slow.complete();
      await pumpEventQueue();

      expect(ready().setAsideRupees, 5000);
    });

    test('UsedReset clears digits without closing', () async {
      await load();
      await type('4000');
      await bloc.dispatch(const UsedAllPressed());

      await bloc.dispatch(const UsedReset());

      expect(ready().rupees, 0);
      expect(ready().replaceNext, isFalse);
      expect(ready().setAsideRupees, 12000);
    });

    test('events before the load are ignored', () async {
      await bloc.dispatch(const UsedKeyPressed('5'));
      await bloc.dispatch(const UsedAllPressed());
      await bloc.dispatch(const UsedSavePressed());
      await bloc.dispatch(const UsedReset());

      expect(bloc.state, const UsedLoading());
    });

    test('closing mid-load does not throw', () async {
      bloc.add(UsedLoadRequested(WorkedExample.insurance));

      await expectLater(bloc.close(), completes);
    });
  });
}
