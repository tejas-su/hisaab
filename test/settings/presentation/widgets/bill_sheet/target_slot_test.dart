import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/saving_sheet.dart';

/// Line 2 of the *Saving up to* slot: how the typed target moves today's share (SPEC BR-23, AC-T3,
/// owner 2026-11-26).
///
/// Insurance moved to the 30th, so its ₹1,000 put-in is still due this cycle, with ₹12,000 set
/// aside; today is 26 Oct 2026.
void main() {
  late SavingSheet sheet;

  setUp(() => sheet = SavingSheet());
  tearDown(() => sheet.dispose());

  final Finder slot = find.byKey(const ValueKey<String>('target-slot'));
  final Finder lineTwo = find.byKey(const ValueKey<String>('target-slot-line-2'));

  RecurringRule dueThisCycle({int? target}) => SavingSheet.insurance(rupees: target).copyWith(
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 9, 30)),
        nextDue: const CalendarDate(2026, 10, 30),
      );

  String shown(WidgetTester tester) => tester.widget<Text>(lineTwo).data!;

  testWidgets('a target that cuts the put-in short: the daily number goes up, spoken in rupees', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await sheet.open(tester, dueThisCycle());
    await sheet.openTarget(tester);

    await sheet.type(tester, '12500');

    expect(shown(tester), matches(RegExp(r'^Your daily number goes up by ₹[\d,]+\.$')));
    expect(tester.getSemantics(slot).label, matches(RegExp(r', Your daily number goes up by [\d,]+ rupees\.$')));
    handle.dispose();
  });

  testWidgets('a target that lets the put-in go in full: the daily number goes down', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await sheet.open(tester, dueThisCycle(target: 12500));
    await sheet.openTarget(tester);

    await sheet.type(tester, '20000');

    expect(shown(tester), matches(RegExp(r'^Your daily number goes down by ₹[\d,]+\.$')));
    expect(tester.getSemantics(lineTwo).label, matches(RegExp(r'^Your daily number goes down by [\d,]+ rupees\.$')));
    handle.dispose();
  });

  testWidgets('a target past this cycle\'s put-in: the daily number doesn\'t change', (WidgetTester tester) async {
    await sheet.open(tester, dueThisCycle());
    await sheet.openTarget(tester);

    await sheet.type(tester, '50000');

    expect(shown(tester), "Your daily number doesn't change.");
  });
}
