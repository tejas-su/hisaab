import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/domain/entities/saving_started.dart';
import 'package:hisaab/spends/domain/usecase/undo_start_saving.dart';
import 'package:hisaab/spends/presentation/bloc/afford_undo_bloc.dart';
import 'package:hisaab/spends/presentation/bloc/afford_undo_event.dart';
import 'package:hisaab/spends/presentation/bloc/afford_undo_state.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/spends/afford_book.dart';

void main() {
  late FakeRecurringRepository recurring;
  late FakeHaptics haptics;
  late AffordUndoBloc bloc;

  final SavingStarted started = SavingStarted(rule: AffordBook.mac(), previous: const Option<RecurringRule>.none());

  setUp(() {
    recurring = FakeRecurringRepository(<RecurringRule>[...AffordBook.rules(), AffordBook.mac()]);
    haptics = FakeHaptics();
    bloc = AffordUndoBloc(
      undo: UndoStartSaving(recurring: recurring),
      haptics: haptics,
    );
  });

  tearDown(() => bloc.close());

  group('AffordUndoBloc (AC-6, E164)', () {
    test('starts idle', () {
      expect(bloc.state, const AffordUndoIdle());
    });

    test('an offered saving shows its Undo', () async {
      await bloc.dispatch(AffordUndoOffered(started));

      expect(bloc.state, AffordUndoShown(started));
    });

    test('Undo deletes a new saving and says Undone with a tick', () async {
      await bloc.dispatch(AffordUndoRequested(started));

      expect(bloc.state, const AffordUndoDone());
      expect(recurring.rules.where((RecurringRule r) => r.id == AffordBook.macId), isEmpty);
      expect(haptics.events, <String>['tick']);
    });

    test("a failed Undo says it couldn't, with a reject, and keeps the saving (E164)", () async {
      recurring.failure = DatabaseFailure('x');
      await bloc.dispatch(AffordUndoRequested(started));

      expect(bloc.state, const AffordUndoFailed());
      expect(haptics.events, <String>['reject']);
      expect(recurring.stopped, isEmpty);
    });

    test('a second Undo while the first is written is dropped', () async {
      final SavingStarted recheck = SavingStarted(rule: AffordBook.mac(), previous: Option<RecurringRule>.of(AffordBook.mac()));
      final Completer<void> gate = Completer<void>();
      recurring.nextUpdateGate = gate;
      bloc
        ..add(AffordUndoRequested(recheck))
        ..add(AffordUndoRequested(recheck));
      await pumpEventQueue();
      gate.complete();
      await pumpEventQueue();

      expect(recurring.updates, hasLength(1));
    });
  });

  test('events and states compare by value', () {
    expect(AffordUndoOffered(started).props, <Object?>[started]);
    expect(AffordUndoRequested(started).props, <Object?>[started]);
    expect(const AffordUndoIdle().props, isEmpty);
    expect(const AffordUndoFailed(), const AffordUndoFailed());
  });
}
