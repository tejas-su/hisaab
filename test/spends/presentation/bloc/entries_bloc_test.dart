import 'dart:async';

import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/spends.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

const PayCycle _october = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3));

void main() {
  late FakeLedgerRepository ledger;
  late FakeCategoryRepository categories;
  late FakeHaptics haptics;
  late EntriesBloc bloc;

  EntriesBloc build({Option<int> filter = const Option<int>.none()}) => EntriesBloc(
        cycle: _october,
        filter: filter,
        ledger: ledger,
        categories: categories,
        deleteEntry: DeleteEntry(ledger: ledger),
        restoreEntry: RestoreEntry(ledger: ledger),
        haptics: haptics,
      );

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    categories = FakeCategoryRepository();
    haptics = FakeHaptics();
    bloc = build();
  });

  tearDown(() async {
    await bloc.close();
    await ledger.dispose();
  });

  EntriesReady ready() => bloc.state as EntriesReady;

  group('EntriesBloc (FR-SP-6)', () {
    test('starts loading', () => expect(bloc.state, const EntriesLoading()));

    test('loads the cycle newest first, grouped by day', () async {
      await bloc.dispatch(const EntriesLoadRequested());
      expect(ready().shown.map((Entry e) => e.id), <int>[6, 5, 4, 3, 2, 1]);
      expect(ready().days.map(((CalendarDate, List<Entry>) d) => (d.$1.day, d.$2.length)), <(int, int)>[(26, 3), (20, 1), (5, 1), (4, 1)]);
    });

    test('offers a chip for each category with entries, in grid order', () async {
      await bloc.dispatch(const EntriesLoadRequested());
      expect(ready().chips.map((Category c) => c.key), <String>['food', 'travel', 'shopping', 'home', 'salary']);
    });

    test('starts on the category it was opened for', () async {
      await bloc.close();
      bloc = build(filter: const Option<int>.of(SeedCategoryIds.food));
      await bloc.dispatch(const EntriesLoadRequested());
      expect(ready().shown.map((Entry e) => e.id), <int>[4, 3]);
    });

    test('filtering narrows to a category with a tick, and None shows all again', () async {
      await bloc.dispatch(const EntriesLoadRequested());
      await bloc.dispatch(const EntriesFilterChanged(Option<int>.of(SeedCategoryIds.travel)));
      expect(ready().shown.map((Entry e) => e.id), <int>[5]);
      await bloc.dispatch(const EntriesFilterChanged(Option<int>.none()));
      expect(ready().shown, hasLength(6));
      expect(haptics.events, <String>['tick', 'tick']);
    });

    test('choosing the current filter again does nothing', () async {
      await bloc.dispatch(const EntriesLoadRequested());
      await bloc.dispatch(const EntriesFilterChanged(Option<int>.none()));
      expect(haptics.events, isEmpty);
    });

    test('filtering does nothing before loading', () async {
      await bloc.dispatch(const EntriesFilterChanged(Option<int>.of(SeedCategoryIds.food)));
      expect(bloc.state, const EntriesLoading());
    });

    test('the filter survives a reload', () async {
      await bloc.dispatch(const EntriesLoadRequested());
      await bloc.dispatch(const EntriesFilterChanged(Option<int>.of(SeedCategoryIds.travel)));
      await bloc.dispatch(const EntriesLoadRequested());
      expect(ready().filter, const Option<int>.of(SeedCategoryIds.travel));
    });

    test('reloads after a ledger write', () async {
      await bloc.dispatch(const EntriesLoadRequested());
      await ledger.add(EntryDraft(amount: Money.fromMajor(10), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today)).run();
      await pumpEventQueue();
      expect(ready().entries, hasLength(7));
    });

    test('emits EntriesFailed when loading fails', () async {
      categories.failure = DatabaseFailure('locked');
      await bloc.dispatch(const EntriesLoadRequested());
      expect(bloc.state, isA<EntriesFailed>());
    });

    test('closing mid-load does not throw', () async {
      bloc.add(const EntriesLoadRequested());
      await expectLater(bloc.close(), completes);
    });

    test('a write during a slow load ends on the fresh list', () async {
      final Completer<void> slowRead = Completer<void>();
      ledger.nextReadGate = slowRead;
      bloc.add(const EntriesLoadRequested());
      await pumpEventQueue();
      await ledger.add(EntryDraft(amount: Money.fromMajor(10), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today)).run();
      await pumpEventQueue();
      slowRead.complete();
      await pumpEventQueue();
      expect(ready().entries, hasLength(7));
    });
  });

  group('EntriesBloc delete and undo (BR-10)', () {
    test('removes the row at once, then offers Undo for it', () async {
      await bloc.dispatch(const EntriesLoadRequested());
      final Entry chai = ready().entries.firstWhere((Entry e) => e.id == 4);
      await bloc.dispatch(EntriesDeleteRequested(chai));
      expect(ready().entries.map((Entry e) => e.id), isNot(contains(4)));
    });

    test('offers Undo with the deleted entry, and undo puts it back', () async {
      await bloc.dispatch(const EntriesLoadRequested());
      final Entry chai = ready().entries.firstWhere((Entry e) => e.id == 4);
      final Future<EntriesState> offered = bloc.stream.firstWhere((EntriesState s) => s is EntriesReady && s.undo.isSome());
      await bloc.dispatch(EntriesDeleteRequested(chai));
      expect((await offered as EntriesReady).undo, Option<Entry>.of(chai));
      await bloc.dispatch(EntriesUndoRequested(chai));
      expect(ready().entries.map((Entry e) => e.id), contains(4));
    });

    test('a failed delete reloads so the row comes back', () async {
      await bloc.dispatch(const EntriesLoadRequested());
      final Entry chai = ready().entries.firstWhere((Entry e) => e.id == 4);
      ledger.failure = DatabaseFailure('locked');
      await bloc.dispatch(EntriesDeleteRequested(chai));
      expect(bloc.state, isA<EntriesFailed>());
    });

    test('a failed undo is quiet', () async {
      await bloc.dispatch(const EntriesLoadRequested());
      ledger.failure = DatabaseFailure('locked');
      await bloc.dispatch(EntriesUndoRequested(WorkedExample.entries.first));
      expect(bloc.state, isA<EntriesReady>());
    });

    test('delete does nothing before loading', () async {
      await bloc.dispatch(EntriesDeleteRequested(WorkedExample.entries.first));
      expect(bloc.state, const EntriesLoading());
    });

    test('closing mid-delete does not throw', () async {
      await bloc.dispatch(const EntriesLoadRequested());
      bloc.add(EntriesDeleteRequested(ready().entries.first));
      await expectLater(bloc.close(), completes);
    });

    test('crossing the swipe threshold plays one light haptic', () async {
      await bloc.dispatch(const EntriesSwipeThresholdReached());
      expect(haptics.events, <String>['threshold']);
    });
  });

  test('events compare by their fields', () {
    expect(const EntriesLoadRequested().props, isEmpty);
    expect(const EntriesFilterChanged(Option<int>.of(1)).props, <Object?>[const Option<int>.of(1)]);
    expect(EntriesDeleteRequested(WorkedExample.entries.first).props, <Object?>[WorkedExample.entries.first]);
    expect(EntriesUndoRequested(WorkedExample.entries.first), EntriesUndoRequested(WorkedExample.entries.first));
  });
}
