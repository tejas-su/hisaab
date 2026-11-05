import 'package:expense_tracker/core/design/hisaab_dimensions.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/settings/presentation/bloc/bill_amount_bloc.dart';
import 'package:expense_tracker/settings/presentation/bloc/bill_amount_event.dart';
import 'package:expense_tracker/settings/presentation/pages/bill_amount_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

const CalendarDate _oct20 = CalendarDate(2026, 10, 20);

RecurringRule _rule(AmountMode mode) => RecurringRule(
      id: 8,
      label: mode == AmountMode.card ? 'Credit card' : 'Electricity',
      amount: Money.fromMajor(1200),
      kind: EntryKind.spent,
      categoryId: 5,
      schedule: const Schedule(frequency: Frequency.monthly, anchor: _oct20),
      nextDue: _oct20,
      amountMode: mode,
    );

void main() {
  late FakeLedgerRepository ledger;
  late FakeRecurringRepository recurring;

  setUp(() {
    ledger = FakeLedgerRepository();
    recurring = FakeRecurringRepository(<RecurringRule>[_rule(AmountMode.varies)]);
  });

  tearDown(() => ledger.dispose());

  /// Opens the sheet and returns what it reports when it closes.
  Future<Future<Option<BillAmountOutcome>>> open(WidgetTester tester, {AmountMode mode = AmountMode.varies, Size size = TestWindows.phone}) async {
    final FakeClock clock = FakeClock(WorkedExample.now);
    final BillAmountBloc bloc = await tester.buildBloc(
      () => BillAmountBloc(
        occurrence: Occurrence(rule: _rule(mode), date: _oct20),
        getLastAmount: GetLastBillAmount(ledger: ledger, clock: clock),
        enter: EnterBillAmount(ledger: ledger, recurring: recurring),
        skip: SkipBillOccurrence(recurring: recurring),
        haptics: FakeHaptics(),
      )..add(const BillAmountLoadRequested()),
    );
    await pumpApp(tester, const Scaffold(), size: size);
    final Future<Option<BillAmountOutcome>> outcome = BillAmountSheet.show(tester.element(find.byType(Scaffold)), bloc);
    await tester.settle();
    return outcome;
  }

  group('BillAmountSheet (D123)', () {
    testWidgets('opens on the keypad with the estimate, the date and the guess', (WidgetTester tester) async {
      await open(tester);
      expect(find.text('Electricity · 20 Oct'), findsOneWidget);
      expect(find.text('₹1,200'), findsOneWidget);
      expect(find.text('You said about ₹1,200'), findsOneWidget);
      expect(find.text("Didn't go out this month"), findsOneWidget);
    });

    testWidgets('after the first time it says last time', (WidgetTester tester) async {
      ledger.entries.add(Entry(
        id: 1,
        amount: Money.fromMajor(1300),
        kind: EntryKind.spent,
        categoryId: 5,
        date: const CalendarDate(2026, 9, 20),
        createdAt: DateTime(2026, 9, 20),
        recurringId: 8,
      ));
      await open(tester);
      expect(find.text('Last time ₹1,300'), findsOneWidget);
    });

    testWidgets('Save enters it, closes, and reports what was entered', (WidgetTester tester) async {
      final Future<Option<BillAmountOutcome>> outcome = await open(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-amount-save')));
      await tester.settle();
      await tester.pumpAndSettle();
      expect(find.byType(BillAmountSheet), findsNothing);
      expect((await outcome).toNullable(), isA<BillAmountWasEntered>());
      expect(ledger.entries.single.amount, Money.fromMajor(1200));
    });

    testWidgets("Didn't go out skips it and reports the skip", (WidgetTester tester) async {
      final Future<Option<BillAmountOutcome>> outcome = await open(tester);
      await tester.tap(find.byKey(const ValueKey<String>('bill-amount-skip')));
      await tester.settle();
      await tester.pumpAndSettle();
      expect((await outcome).toNullable(), isA<BillAmountWasSkipped>());
    });

    testWidgets('Back closes it with nothing done', (WidgetTester tester) async {
      final Future<Option<BillAmountOutcome>> outcome = await open(tester);
      Navigator.of(tester.element(find.byType(BillAmountSheet))).pop();
      await tester.pumpAndSettle();
      expect(await outcome, const Option<BillAmountOutcome>.none());
    });

    testWidgets('a card bill says why it isn\'t counted', (WidgetTester tester) async {
      recurring.rules = <RecurringRule>[_rule(AmountMode.card)];
      await open(tester, mode: AmountMode.card);
      expect(find.text('Credit card · 20 Oct'), findsOneWidget);
      expect(find.textContaining("It isn't counted again."), findsOneWidget);
    });

    testWidgets('a failed save says so and stays open', (WidgetTester tester) async {
      await open(tester);
      ledger.failure = DatabaseFailure('disk');
      await tester.tap(find.byKey(const ValueKey<String>('bill-amount-save')));
      await tester.settle();
      expect(find.byType(BillAmountSheet), findsOneWidget);
      expect(find.text("Couldn't save. Try again."), findsOneWidget);
    });

    testWidgets('the title starts on the page gutter (D122)', (WidgetTester tester) async {
      await open(tester);
      final double sheet = tester.getTopLeft(find.byType(BillAmountSheet)).dx;
      expect(tester.getTopLeft(find.text('Electricity · 20 Oct')).dx - sheet, HisaabSpacing.gutter);
    });

    testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await open(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
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
}
