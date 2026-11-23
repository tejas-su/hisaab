import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/period_calculator.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/presentation/bloc/bill_sheet_bloc.dart';
import 'package:hisaab/settings/presentation/bloc/bill_sheet_state.dart';
import 'package:hisaab/settings/presentation/pages/bill_sheet.dart';
import 'package:material_ui/material_ui.dart';
import 'package:fpdart/fpdart.dart';

import 'bloc_dispatch.dart';
import 'fakes/fake_budget_settings_repository.dart';
import 'fakes/fake_category_repository.dart';
import 'fakes/fake_clock.dart';
import 'fakes/fake_haptics.dart';
import 'fakes/fake_ledger_repository.dart';
import 'fakes/fake_recurring_repository.dart';
import 'fixtures/ledger/worked_example.dart';
import 'pump_app.dart';

/// A saving's sheet over a blank screen, wired from fakes as `routes.dart` wires it, for the
/// *Saving up to* and reached-choice tests (SPEC FR-SE-1 AC-T1 to AC-T12).
///
/// Insurance (₹1,000 on the 5th, next 5 Nov 2026) starts with ₹12,000 set aside; today is
/// 26 Oct 2026.
final class SavingSheet {
  SavingSheet()
      : recurring = FakeRecurringRepository(WorkedExample.rules),
        ledger = FakeLedgerRepository(<Entry>[...WorkedExample.entries, ...WorkedExample.insurancePutIns]),
        categories = FakeCategoryRepository(),
        haptics = FakeHaptics();

  final FakeRecurringRepository recurring;
  final FakeLedgerRepository ledger;
  final FakeCategoryRepository categories;
  final FakeHaptics haptics;

  /// Insurance with a target of [rupees], or none.
  static RecurringRule insurance({int? rupees}) => WorkedExample.insurance.copyWith(
        target: Option<Money>.fromNullable(rupees == null ? null : Money.fromMajor(rupees)),
      );

  /// Opens [rule]'s sheet and returns what it reports when it closes.
  Future<Future<BillSheetOutcome>> open(
    WidgetTester tester,
    RecurringRule rule, {
    Size size = TestWindows.phone,
    double textScale = 1,
  }) async {
    recurring.rules = <RecurringRule>[...WorkedExample.rules.where((RecurringRule r) => r.id != rule.id), rule];
    final FakeClock clock = FakeClock(WorkedExample.now);
    final BillSheetBloc bloc = await tester.buildBloc(
      () => BillSheetBloc(
        rule: rule,
        editBill: EditBill(recurring: recurring, categories: categories, clock: clock),
        getStatus: GetBillStatus(
          ledger: ledger,
          clock: clock,
          summary: GetCycleSummary(
            ledger: ledger,
            recurring: recurring,
            settings: FakeBudgetSettingsRepository(),
            periods: const PeriodCalculator(),
            clock: clock,
          ),
        ),
        haptics: haptics,
        getSetAside: GetSetAside(recurring: recurring, ledger: ledger),
        useFromSavings: UseFromSavings(ledger: ledger, categories: categories, clock: clock),
        deleteBill: DeleteBill(recurring: recurring),
        deleteEntry: DeleteEntry(ledger: ledger),
        clock: clock,
      ),
    );
    await pumpApp(tester, const Scaffold(), size: size, textScale: textScale);
    final Future<BillSheetOutcome> outcome = BillSheet.show(tester.element(find.byType(Scaffold)), bloc);
    await tester.settle();
    return outcome;
  }

  /// Taps the *Saving up to* row and waits for the question.
  Future<void> openTarget(WidgetTester tester) async {
    final Finder row = find.byKey(const ValueKey<String>('bill-row-target'));
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.settle();
  }

  /// Types [digits] on the keypad.
  Future<void> type(WidgetTester tester, String digits) async {
    for (final String digit in digits.split('')) {
      await tester.tap(find.byKey(ValueKey<String>('keypad-$digit')));
      await tester.settle();
    }
  }

  /// Closes the fakes.
  Future<void> dispose() async {
    await recurring.dispose();
    await ledger.dispose();
  }
}
