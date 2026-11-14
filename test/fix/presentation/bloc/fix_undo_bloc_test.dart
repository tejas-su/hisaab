import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/fix/presentation/bloc/fix_undo_bloc.dart';
import 'package:hisaab/fix/presentation/bloc/fix_undo_event.dart';
import 'package:hisaab/fix/presentation/bloc/fix_undo_state.dart';
import 'package:hisaab/ledger/ledger.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fixtures/ledger/not_logged.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

/// The Settings door's Undo (FR-FX-5 AC-4, AC-5; P4).
void main() {
  late FakeLedgerRepository ledger;
  late FakeHaptics haptics;
  late FixUndoBloc bloc;
  late FixOutcome outcome;

  setUp(() {
    final Entry fix = notLogged(4200, WorkedExample.today);
    ledger = FakeLedgerRepository(<Entry>[...WorkedExample.entries, fix]);
    haptics = FakeHaptics();
    outcome = FixOutcome(entry: fix, safeToday: Money.fromMajor(963));
    bloc = FixUndoBloc(deleteEntry: DeleteEntry(ledger: ledger), haptics: haptics);
  });

  tearDown(() async {
    await bloc.close();
    await ledger.dispose();
  });

  test('starts idle', () {
    expect(bloc.state, const FixUndoIdle());
  });

  test('an offered outcome is shown', () async {
    await bloc.dispatch(FixUndoOffered(outcome));

    expect(bloc.state, FixUndoShown(outcome));
  });

  test('Undo deletes the entry, fires tick and reports Undone', () async {
    await bloc.dispatch(FixUndoOffered(outcome));

    await bloc.dispatch(FixUndoRequested(outcome));

    expect(ledger.entries.any((Entry e) => e.isNotLogged), isFalse);
    expect(haptics.events, <String>['tick']);
    expect(bloc.state, const FixUndoDone());
  });

  test('a failed delete keeps the offer and fires nothing', () async {
    await bloc.dispatch(FixUndoOffered(outcome));
    ledger.failure = DatabaseFailure('down');

    await bloc.dispatch(FixUndoRequested(outcome));

    expect(haptics.events, isEmpty);
    expect(bloc.state, FixUndoShown(outcome));
  });
}
