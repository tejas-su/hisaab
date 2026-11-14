import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/fix/presentation/bloc/fix_event.dart';
import 'package:hisaab/fix/presentation/bloc/fix_state.dart';
import 'package:hisaab/fix/presentation/bloc/fix_undo_event.dart';
import 'package:hisaab/fix/presentation/bloc/fix_undo_state.dart';
import 'package:hisaab/fix/presentation/fix_slot_copy.dart';
import 'package:hisaab/home/presentation/bloc/home_event.dart';
import 'package:hisaab/ledger/ledger.dart';

import '../helpers/fixtures/ledger/fix_summaries.dart';
import '../helpers/fixtures/ledger/not_logged.dart';
import '../helpers/fixtures/ledger/worked_example.dart';

/// Blocs and previews compare by value, so state-sequence tests and rebuilds can trust them.
void main() {
  final FixOutcome outcome = FixOutcome(entry: notLogged(4200, WorkedExample.today), safeToday: Money.fromMajor(963));
  final Money held = Money.fromMajor(17430);

  group('FixBloc events and states compare by their fields', () {
    test('events', () {
      expect(const FixLoadRequested(), const FixLoadRequested());
      expect(const FixKeyPressed('5'), const FixKeyPressed('5'));
      expect(const FixKeyPressed('5'), isNot(const FixKeyPressed('6')));
      expect(const FixBackspacePressed(), const FixBackspacePressed());
      expect(const FixCleared(), const FixCleared());
      expect(const FixSavePressed(), const FixSavePressed());
      expect(const FixGuardAnswered(yes: true), const FixGuardAnswered(yes: true));
      expect(const FixGuardAnswered(yes: true), isNot(const FixGuardAnswered(yes: false)));
      expect(const FixBackPressed(), const FixBackPressed());
    });

    test('states', () {
      final CycleSummary summary = fixSummary();
      final Failure failure = DatabaseFailure('down');
      expect(const FixLoading(), const FixLoading());
      expect(FixFailed(failure), FixFailed(failure));
      expect(FixDone(outcome), FixDone(outcome));
      expect(FixGuard(openedAt: DateTime(2026), seenGapRupees: 1), FixGuard(openedAt: DateTime(2026), seenGapRupees: 1));
      expect(FixReady(summary: summary), FixReady(summary: summary));
      expect(FixReady(summary: summary), isNot(FixReady(summary: summary, rejections: 1)));
      expect(FixReady(summary: summary).copyWith(typed: const Option<int>.of(5)).typed, const Option<int>.of(5));
    });
  });

  group('FixUndoBloc events and states compare by their fields', () {
    test('events and states', () {
      expect(FixUndoOffered(outcome), FixUndoOffered(outcome));
      expect(FixUndoRequested(outcome), FixUndoRequested(outcome));
      expect(const FixUndoIdle(), const FixUndoIdle());
      expect(FixUndoShown(outcome), FixUndoShown(outcome));
      expect(const FixUndoDone(), const FixUndoDone());
    });
  });

  group('previews compare by their fields', () {
    final Money gap = Money.fromMajor(4200);
    final Money after = Money.fromMajor(1383);
    final Money perDay = Money.fromMajor(467);

    test('every state', () {
      expect(FixEmpty(held: held), FixEmpty(held: held));
      expect(FixEqual(held: held), FixEqual(held: held));
      expect(FixClose(held: held), FixClose(held: held));
      expect(FixLower(held: held, gap: gap, shareAfter: after, perDay: perDay, lastDay: false),
          FixLower(held: held, gap: gap, shareAfter: after, perDay: perDay, lastDay: false));
      expect(FixLower(held: held, gap: gap, shareAfter: after, perDay: perDay, lastDay: false),
          isNot(FixLower(held: held, gap: gap, shareAfter: after, perDay: perDay, lastDay: true)));
      expect(FixShort(held: held, gap: gap, shareAfter: after, perDay: perDay, short: gap),
          FixShort(held: held, gap: gap, shareAfter: after, perDay: perDay, short: gap));
      expect(FixOverToday(held: held, gap: gap, shareAfter: after, perDay: perDay, over: gap),
          FixOverToday(held: held, gap: gap, shareAfter: after, perDay: perDay, over: gap));
      expect(FixHigher(held: held, gap: gap, shareAfter: after, perDay: perDay, lastDay: true),
          FixHigher(held: held, gap: gap, shareAfter: after, perDay: perDay, lastDay: true));
      expect(FixLarge(held: held, gap: gap, shareAfter: after, perDay: perDay), FixLarge(held: held, gap: gap, shareAfter: after, perDay: perDay));
      expect(FixPost(kind: EntryKind.spent, amount: gap), FixPost(kind: EntryKind.spent, amount: gap));
    });

    test('the outcome, the params and the slot lines', () {
      expect(outcome, FixOutcome(entry: notLogged(4200, WorkedExample.today), safeToday: Money.fromMajor(963)));
      expect(const FixParams(typedRupees: 1, seenGapRupees: 2), const FixParams(typedRupees: 1, seenGapRupees: 2));
      expect(const FixSlotLines(stateClass: 'a', line1: 'x'), const FixSlotLines(stateClass: 'a', line1: 'x'));
      expect(const FixSlotLines(stateClass: 'a', line1: 'x', line2: 'y').sentence, 'x y');
    });
  });

  group('Home events compare by their fields', () {
    test('the fix events', () {
      expect(HomeFixDone(outcome), HomeFixDone(outcome));
      expect(HomeFixUndoRequested(outcome.entry), HomeFixUndoRequested(outcome.entry));
    });
  });
}
