
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/settings/presentation/bloc/put_in_extra_bloc.dart';
import 'package:expense_tracker/settings/presentation/bloc/put_in_extra_event.dart';
import 'package:expense_tracker/settings/presentation/bloc/put_in_extra_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;
  late FakeHaptics haptics;

  setUp(() {
    ledger = FakeLedgerRepository(<Entry>[
      ...WorkedExample.entries,
      Entry(
        id: 50,
        amount: Money.fromMajor(5000),
        kind: EntryKind.saved,
        categoryId: SeedCategoryIds.saved,
        date: const CalendarDate(2026, 10, 10),
        createdAt: WorkedExample.now,
        recurringId: 4,
      ),
    ]);
    recurring = FakeRecurringRepository(<RecurringRule>[...WorkedExample.rules, WorkedExample.rd]);
    haptics = FakeHaptics();
  });

  tearDown(() => ledger.dispose());

  PutInExtraBloc build({DateTime? now}) {
    final FakeClock clock = FakeClock(now ?? WorkedExample.now);
    final GetCycleSummary summary = GetCycleSummary(
      ledger: ledger,
      recurring: recurring,
      settings: FakeBudgetSettingsRepository(),
      periods: const PeriodCalculator(),
      clock: clock,
    );
    final PutInExtraBloc bloc = PutInExtraBloc(
      getCycleSummary: summary,
      putInExtra: PutInExtra(getCycleSummary: summary, ledger: ledger, categories: FakeCategoryRepository(), clock: clock),
      haptics: haptics,
    );
    addTearDown(bloc.close);
    return bloc;
  }

  Future<PutInExtraBloc> loaded({DateTime? now}) async {
    final PutInExtraBloc bloc = build(now: now);
    await bloc.dispatch(const PutInExtraLoadRequested());
    return bloc;
  }

  Future<void> type(PutInExtraBloc bloc, String digits) async {
    for (final String key in digits.split('')) {
      await bloc.dispatch(PutInExtraKeyPressed(key));
    }
  }

  PutInExtraReady ready(PutInExtraBloc bloc) => bloc.state as PutInExtraReady;

  group('PutInExtraBloc (D120)', () {
    test('starts loading', () => expect(build().state, const PutInExtraLoading()));

    test('loads today\'s summary', () async {
      expect(ready(await loaded()).roomRupees, 11230);
    });

    test('₹500 previews each day ₹62 less', () async {
      final PutInExtraBloc bloc = await loaded();
      await type(bloc, '500');
      expect(ready(bloc).preview, Option<PutInPreview>.of(EachDayLess(Money.fromMajor(62))));
    });

    test('no preview at ₹0', () async {
      expect(ready(await loaded()).preview, const Option<PutInPreview>.none());
    });

    test('a key past what is left is refused', () async {
      final PutInExtraBloc bloc = await loaded();
      await type(bloc, '11230');
      expect(ready(bloc).rupees, 11230);
      await type(bloc, '0');
      expect((ready(bloc).rupees, ready(bloc).rejections), (11230, 1));
      expect(haptics.events, contains('reject'));
    });

    test('⌫ drops a digit and clear empties it', () async {
      final PutInExtraBloc bloc = await loaded();
      await type(bloc, '500');
      await bloc.dispatch(const PutInExtraBackspacePressed());
      expect(ready(bloc).rupees, 50);
      await bloc.dispatch(const PutInExtraCleared());
      expect(ready(bloc).rupees, 0);
    });

    test('on the last day the preview says payday is tomorrow', () async {
      final PutInExtraBloc bloc = await loaded(now: DateTime(2026, 11, 3, 10));
      await type(bloc, '5');
      expect(ready(bloc).preview, const Option<PutInPreview>.of(PaydayTomorrow()));
    });

    test('with nothing left, Save does nothing', () async {
      ledger.entries.add(Entry(
        id: 60,
        amount: Money.fromMajor(12000),
        kind: EntryKind.spent,
        categoryId: SeedCategoryIds.food,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
      ));
      final PutInExtraBloc bloc = await loaded();
      final int before = ledger.entries.length;
      expect(ready(bloc).nothingLeft, isTrue);
      await bloc.dispatch(const PutInExtraSavePressed());
      expect(ledger.entries, hasLength(before));
      expect(bloc.state, isA<PutInExtraReady>());
    });

    test('Save puts it in and finishes', () async {
      final PutInExtraBloc bloc = await loaded();
      await type(bloc, '500');
      await bloc.dispatch(const PutInExtraSavePressed());
      expect(bloc.state, const PutInExtraDone());
      expect((ledger.entries.last.amount, ledger.entries.last.kind), (Money.fromMajor(500), EntryKind.saved));
      expect(haptics.events, contains('success'));
    });

    test('a second Save while the first is in flight is dropped', () async {
      final PutInExtraBloc bloc = await loaded();
      await type(bloc, '500');
      final int before = ledger.entries.length;
      bloc
        ..add(const PutInExtraSavePressed())
        ..add(const PutInExtraSavePressed());
      await bloc.stream.firstWhere((PutInExtraState s) => s is PutInExtraDone);
      expect(ledger.entries, hasLength(before + 1));
    });

    test('a failed save says so', () async {
      final PutInExtraBloc bloc = await loaded();
      await type(bloc, '500');
      ledger.failure = DatabaseFailure('disk full');
      await bloc.dispatch(const PutInExtraSavePressed());
      expect((ready(bloc).saveFailed, ready(bloc).saving), (true, false));
    });

    test('a failed load says so', () async {
      ledger.failure = DatabaseFailure('disk full');
      final PutInExtraBloc bloc = await loaded();
      expect(bloc.state, isA<PutInExtraFailed>());
    });
  });

  group('PutInExtra events and states compare by their fields', () {
    test('events', () {
      expect(const PutInExtraKeyPressed('5'), const PutInExtraKeyPressed('5'));
      expect(const PutInExtraKeyPressed('5'), isNot(const PutInExtraKeyPressed('6')));
      expect(const PutInExtraLoadRequested(), const PutInExtraLoadRequested());
      expect(const PutInExtraBackspacePressed(), const PutInExtraBackspacePressed());
      expect(const PutInExtraCleared(), const PutInExtraCleared());
      expect(const PutInExtraSavePressed(), const PutInExtraSavePressed());
    });

    test('states and previews', () {
      final Failure failure = DatabaseFailure('x');
      expect(PutInExtraFailed(failure), PutInExtraFailed(failure));
      expect(const PutInExtraLoading(), isNot(const PutInExtraDone()));
      expect(const PaydayTomorrow(), const PaydayTomorrow());
      expect(const PaydayTomorrow().props, isEmpty);
    });
  });
}
