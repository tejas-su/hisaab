import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/month_start.dart';
import 'package:expense_tracker/core/time/period_calculator.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/settings/presentation/bloc/put_in_extra_bloc.dart';
import 'package:expense_tracker/settings/presentation/bloc/put_in_extra_event.dart';
import 'package:expense_tracker/settings/presentation/pages/put_in_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_budget_settings_repository.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;

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
  });

  tearDown(() => ledger.dispose());

  Future<void> open(WidgetTester tester, {Size size = TestWindows.phone, MonthStart monthStart = MonthStart.payday}) async {
    final FakeClock clock = FakeClock(WorkedExample.now);
    final GetCycleSummary summary = GetCycleSummary(
      ledger: ledger,
      recurring: recurring,
      settings: FakeBudgetSettingsRepository(BudgetSettings(monthStart: monthStart)),
      periods: const PeriodCalculator(),
      clock: clock,
    );
    final PutInExtraBloc bloc = await tester.buildBloc(
      () => PutInExtraBloc(
        getCycleSummary: summary,
        putInExtra: PutInExtra(getCycleSummary: summary, ledger: ledger, categories: FakeCategoryRepository(), clock: clock),
        haptics: FakeHaptics(),
      )..add(const PutInExtraLoadRequested()),
    );
    await pumpApp(tester, const Scaffold(), size: size);
    PutInSheet.show(tester.element(find.byType(Scaffold)), bloc).ignore();
    await tester.settle();
  }

  Future<void> keys(WidgetTester tester, String digits) async {
    for (final String key in digits.split('')) {
      await tester.tap(find.byKey(ValueKey<String>('keypad-$key')));
      await tester.settle();
    }
  }

  group('PutInSheet (D120)', () {
    testWidgets('the sheet shows the preview and closes on Save', (WidgetTester tester) async {
      await open(tester);
      expect(find.text('How much extra are you putting in?'), findsOneWidget);
      await keys(tester, '500');
      expect(find.text('Each day till payday gets ₹62 less'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('put-in-save')));
      await tester.settle();
      await tester.pumpAndSettle();
      expect(find.byType(PutInSheet), findsNothing);
      expect(ledger.entries.last.amount, Money.fromMajor(500));
    });

    testWidgets('month-end wording', (WidgetTester tester) async {
      await open(tester, monthStart: MonthStart.firstOfMonth);
      await keys(tester, '500');
      expect(find.textContaining('Each day till month end gets'), findsOneWidget);
    });

    for (final Size size in <Size>[
      TestWindows.phone,
      TestWindows.phoneLandscape,
      TestWindows.smallPhone,
      TestWindows.foldableUnfolded,
      TestWindows.foldableLandscape,
      TestWindows.tablet,
    ]) {
      testWidgets('fits ${size.width.toInt()}×${size.height.toInt()}', (WidgetTester tester) async {
        await open(tester, size: size);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('PutInSheet failures (D120)', () {
    testWidgets('a failed load says so', (WidgetTester tester) async {
      ledger.failure = DatabaseFailure('x');
      await open(tester);
      expect(find.text("Couldn't load your money."), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('put-in-save')), findsNothing);
    });

    testWidgets('⌫ and long-press clear reach the bloc', (WidgetTester tester) async {
      await open(tester);
      await keys(tester, '50');
      await tester.tap(find.bySemanticsLabel('Delete last digit. Long-press to clear'));
      await tester.settle();
      expect(find.text('₹5'), findsOneWidget);
      await tester.longPress(find.bySemanticsLabel('Delete last digit. Long-press to clear'));
      await tester.settle();
      expect(find.text('₹5'), findsNothing);
    });

    testWidgets('a failed save says so and stays open', (WidgetTester tester) async {
      await open(tester);
      await keys(tester, '500');
      ledger.failure = DatabaseFailure('x');
      await tester.tap(find.byKey(const ValueKey<String>('put-in-save')));
      await tester.settle();
      expect(find.byType(PutInSheet), findsOneWidget);
      expect(find.textContaining('Try again'), findsOneWidget);
    });
  });
}
