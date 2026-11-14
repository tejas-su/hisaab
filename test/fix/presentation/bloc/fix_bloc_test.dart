import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/fix/presentation/bloc/fix_bloc.dart';
import 'package:hisaab/fix/presentation/bloc/fix_event.dart';
import 'package:hisaab/fix/presentation/bloc/fix_state.dart';
import 'package:hisaab/ledger/ledger.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

/// FixBloc against the worked example (H 17,430, I ÷ 10 = 4,500): FR-FX-2 to FR-FX-5.
void main() {
  late FakeLedgerRepository ledger;
  late FakeBudgetSettingsRepository settings;
  late FakeClock clock;
  late FakeHaptics haptics;
  late GetCycleSummary summary;
  late FixBloc bloc;

  FixBloc build({bool successOnSave = true}) => FixBloc(
        getCycleSummary: summary,
        fix: FixMyNumberUseCase(
          summary: summary,
          ledger: ledger,
          categories: FakeCategoryRepository(),
          settings: settings,
          clock: clock,
        ),
        ledger: ledger,
        clock: clock,
        haptics: haptics,
        successOnSave: successOnSave,
      );

  setUp(() async {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    settings = FakeBudgetSettingsRepository();
    clock = FakeClock(WorkedExample.now);
    haptics = FakeHaptics();
    summary = GetCycleSummary(
      ledger: ledger,
      recurring: FakeRecurringRepository(<RecurringRule>[...WorkedExample.rules]),
      settings: settings,
      periods: const PeriodCalculator(),
      clock: clock,
    );
    bloc = build();
  });

  tearDown(() async {
    await bloc.close();
    await ledger.dispose();
  });

  Future<FixReady> ready() async {
    await bloc.dispatch(const FixLoadRequested());
    return bloc.state as FixReady;
  }

  Future<void> type(String digits) async {
    for (final String digit in digits.split('')) {
      await bloc.dispatch(FixKeyPressed(digit));
    }
  }

  FixReady now() => bloc.state as FixReady;

  group('opening', () {
    test('starts loading and the amount is empty once ready; H is in the state but the preview is empty', () async {
      expect(bloc.state, isA<FixLoading>());

      final FixReady state = await ready();

      expect(state.typed, const Option<int>.none());
      expect(state.preview, isA<FixEmpty>());
      expect(state.notice, FixNotice.none);
    });

    test('a failed read is FixFailed and Try again reloads', () async {
      ledger.failure = DatabaseFailure('down');
      await bloc.dispatch(const FixLoadRequested());
      expect(bloc.state, isA<FixFailed>());

      ledger.failure = null;
      await bloc.dispatch(const FixLoadRequested());

      expect(bloc.state, isA<FixReady>());
    });

    test('keys while loading or failed change nothing', () async {
      await bloc.dispatch(const FixKeyPressed('5'));

      expect(bloc.state, isA<FixLoading>());
    });
  });

  group('typing', () {
    test('digits build the amount and update the preview', () async {
      await ready();

      await type('13230');

      expect(now().typed, const Option<int>.of(13230));
      expect(now().preview, isA<FixLower>());
      expect(haptics.events, everyElement('tick'));
    });

    test('backspacing to empty restores the empty state; typed 0 is not empty (C5)', () async {
      await ready();
      await type('0');
      expect(now().typed, const Option<int>.of(0));

      await bloc.dispatch(const FixBackspacePressed());

      expect(now().typed, const Option<int>.none());
      await type('12');
      await bloc.dispatch(const FixBackspacePressed());
      expect(now().typed, const Option<int>.of(1));
    });

    test('a long-press on backspace empties the amount', () async {
      await ready();
      await type('123');

      await bloc.dispatch(const FixCleared());

      expect(now().typed, const Option<int>.none());
    });

    test('a 10th digit: reject haptic, rejections + 1, digits unchanged', () async {
      await ready();
      await type('999999999');

      await bloc.dispatch(const FixKeyPressed('1'));

      expect(now().typed, const Option<int>.of(999999999));
      expect(now().rejections, 1);
      expect(haptics.events.last, 'reject');
    });

    test('the next key clears a notice', () async {
      await ready();
      await type('47430');
      await bloc.dispatch(const FixSavePressed());
      clock.advance(FixBloc.guardIgnoreWindow);
      await bloc.dispatch(const FixGuardAnswered(yes: false));
      expect(now().notice, FixNotice.countOnly);

      await type('1');

      expect(now().notice, FixNotice.none);
    });
  });

  group('Fix it', () {
    test('on a lower gap saves, emits FixDone with the new hero, success haptic once', () async {
      await ready();
      await type('13230');
      haptics.events.clear();

      await bloc.dispatch(const FixSavePressed());

      final FixDone done = bloc.state as FixDone;
      expect(done.outcome.entry.amount, Money.fromMajor(4200));
      expect(done.outcome.entry.isNotLogged, isTrue);
      expect(done.outcome.safeToday, Money.fromMajor(963));
      expect(haptics.events, <String>['success']);
    });

    test('with successOnSave off the bloc fires no haptic itself (Home fires it as the hero rolls)', () async {
      await bloc.close();
      bloc = build(successOnSave: false);
      await ready();
      await type('13230');
      haptics.events.clear();

      await bloc.dispatch(const FixSavePressed());

      expect(bloc.state, isA<FixDone>());
      expect(haptics.events, isEmpty);
    });

    test('a hero that would be below zero is stated as ₹0', () async {
      await ready();
      await type('1000');

      await bloc.dispatch(const FixSavePressed());

      expect((bloc.state as FixDone).outcome.safeToday, Money.zero);
    });

    test('a double Fix it makes one entry (E85)', () async {
      await ready();
      await type('13230');
      final Completer<void> gate = Completer<void>();
      ledger.nextAddGate = gate;

      bloc
        ..add(const FixSavePressed())
        ..add(const FixSavePressed());
      await pumpEventQueue();
      expect(now().saving, isTrue);
      gate.complete();
      await pumpEventQueue();

      expect(ledger.saved, hasLength(1));
    });

    test('Fix it on equal, close or empty does nothing', () async {
      await ready();
      await bloc.dispatch(const FixSavePressed());
      await type('17430');
      await bloc.dispatch(const FixSavePressed());

      expect(ledger.saved, isEmpty);
      expect(bloc.state, isA<FixReady>());
    });

    test('a failed write keeps the digits: saveFailed notice, reject haptic, Fix it on again', () async {
      await ready();
      await type('13230');
      ledger.failure = DatabaseFailure('down');
      haptics.events.clear();

      await bloc.dispatch(const FixSavePressed());

      expect(now().notice, FixNotice.saveFailed);
      expect(now().typed, const Option<int>.of(13230));
      expect(now().saving, isFalse);
      expect(haptics.events, <String>['reject']);
    });

    test('a stale save refreshes the preview, says changed and fires reject', () async {
      await ready();
      await type('13230');
      haptics.events.clear();
      // why: added straight to the list, so the change stream stays silent, as a missed event would.
      ledger.entries.add(Entry(
        id: 700,
        amount: Money.fromMajor(500),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.food,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
      ));

      await bloc.dispatch(const FixSavePressed());

      expect(ledger.saved, isEmpty);
      expect(now().notice, FixNotice.changed);
      expect(now().preview.held, Money.fromMajor(16930));
      expect(haptics.events, <String>['reject']);
    });
  });

  group('the guard (FR-FX-4)', () {
    Future<void> openGuard() async {
      await ready();
      await type('47430');
      await bloc.dispatch(const FixSavePressed());
    }

    test('Fix it on a large gap posts nothing and opens the guard', () async {
      await openGuard();

      expect(ledger.saved, isEmpty);
      expect(now().guard.isSome(), isTrue);
      expect(now().preview, isA<FixLarge>());
    });

    test('an answer within 300 ms of the swap is ignored; at 300 ms it is accepted', () async {
      await openGuard();
      clock.advance(const Duration(milliseconds: 299));

      await bloc.dispatch(const FixGuardAnswered(yes: true));
      expect(now().guard.isSome(), isTrue);
      expect(ledger.saved, isEmpty);

      clock.advance(const Duration(milliseconds: 1));
      await bloc.dispatch(const FixGuardAnswered(yes: true));

      expect(bloc.state, isA<FixDone>());
      expect((bloc.state as FixDone).outcome.entry.kind, EntryKind.got);
      expect((bloc.state as FixDone).outcome.entry.amount, Money.fromMajor(30000));
    });

    test('No clears the digits, returns to the keypad and sets countOnly', () async {
      await openGuard();
      clock.advance(const Duration(milliseconds: 300));

      await bloc.dispatch(const FixGuardAnswered(yes: false));

      expect(now().guard.isNone(), isTrue);
      expect(now().typed, const Option<int>.none());
      expect(now().notice, FixNotice.countOnly);
      expect(ledger.saved, isEmpty);
    });

    test('Back in the guard acts as No at once, with no 300 ms wait', () async {
      await openGuard();

      await bloc.dispatch(const FixBackPressed());

      expect(now().guard.isNone(), isTrue);
      expect(now().notice, FixNotice.countOnly);
    });

    test('Back on the keypad changes nothing (the page closes itself)', () async {
      await ready();
      await type('5');

      await bloc.dispatch(const FixBackPressed());

      expect(now().typed, const Option<int>.of(5));
    });

    test('keys while the guard is open are ignored', () async {
      await openGuard();

      await bloc.dispatch(const FixKeyPressed('1'));

      expect(now().typed, const Option<int>.of(47430));
    });

    test('a failure after Yes returns to the keypad with saveFailed', () async {
      await openGuard();
      clock.advance(const Duration(milliseconds: 300));
      ledger.failure = DatabaseFailure('down');

      await bloc.dispatch(const FixGuardAnswered(yes: true));

      expect(now().guard.isNone(), isTrue);
      expect(now().notice, FixNotice.saveFailed);
    });

    test('H changes while the guard is open: the panel stays; Yes re-checks, posts nothing, notice changed', () async {
      await openGuard();
      ledger.entries.add(Entry(
        id: 702,
        amount: Money.fromMajor(900),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.food,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
      ));
      await bloc.dispatch(const FixLoadRequested());
      expect(now().guard.isSome(), isTrue);
      clock.advance(const Duration(milliseconds: 300));

      await bloc.dispatch(const FixGuardAnswered(yes: true));

      expect(ledger.saved, isEmpty);
      expect(now().guard.isNone(), isTrue);
      expect(now().notice, FixNotice.changed);
    });
  });

  group('the ledger changing behind the sheet (E84)', () {
    test('a change reloads H and keeps the digits; the notice says changed while a gap remains', () async {
      await ready();
      await type('13230');

      ledger.entries.add(Entry(
        id: 703,
        amount: Money.fromMajor(500),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.food,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
      ));
      await bloc.dispatch(const FixLoadRequested());

      expect(now().typed, const Option<int>.of(13230));
      expect(now().preview.held, Money.fromMajor(16930));
      expect(now().notice, FixNotice.changed);
    });

    test('with nothing typed a change just refreshes H, no notice', () async {
      await ready();
      ledger.entries.add(Entry(
        id: 704,
        amount: Money.fromMajor(500),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.food,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
      ));

      await bloc.dispatch(const FixLoadRequested());

      expect(now().notice, FixNotice.none);
      expect(now().preview.held, Money.fromMajor(16930));
    });

    test('a write on the ledger stream reloads the sheet by itself', () async {
      await ready();

      ledger.entries.add(Entry(
        id: 705,
        amount: Money.fromMajor(500),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.food,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
      ));
      await ledger.add(const EntryDraft(
        amount: Money(100),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.food,
        date: WorkedExample.today,
      )).run();
      await pumpEventQueue();

      expect(now().preview.held, Money.fromMajor(16929));
    });

    test('a reload restarts: an older, slower read does not land last', () async {
      await ready();
      final Completer<void> gate = Completer<void>();
      ledger.nextReadGate = gate;
      bloc.add(const FixLoadRequested());
      await pumpEventQueue();
      ledger.entries.add(Entry(
        id: 706,
        amount: Money.fromMajor(500),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.food,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
      ));

      await bloc.dispatch(const FixLoadRequested());
      gate.complete();
      await pumpEventQueue();

      expect(now().preview.held, Money.fromMajor(16930));
    });
  });

  test('closing mid-request does not throw', () async {
    bloc.add(const FixLoadRequested());

    await expectLater(bloc.close(), completes);
  });
}
