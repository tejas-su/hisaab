import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:hisaab/app/hisaab_app.dart';
import 'package:hisaab/app/routes.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/home/presentation/widgets/due_soon_row.dart';
import 'package:hisaab/home/presentation/widgets/install_line_row.dart';
import 'package:hisaab/home/presentation/widgets/reached_line_row.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_services.dart';
import '../helpers/fixtures/ledger/categories.dart';
import '../helpers/fixtures/ledger/worked_example.dart';
import '../helpers/pump_app.dart';

final Money _target = Money.fromMajor(12000);

/// Insurance with ₹12,000 set aside and a target of ₹12,000, next due on 5 Nov (not due soon).
final RecurringRule _reachedInsurance = WorkedExample.insurance.copyWith(target: Option<Money>.of(_target));

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

/// Home's reached line through the app's wiring (SPEC FR-HO-3 AC-R1 to AC-R5, E149, E150, D173).
void main() {
  late FakeServices services;

  tearDown(() => services.dispose());

  Future<void> boot(
    WidgetTester tester, {
    RecurringRule? saving,
    List<RecurringRule> bills = const <RecurringRule>[],
    Size size = TestWindows.phone,
    List<DisplayFeature> displayFeatures = const <DisplayFeature>[],
  }) async {
    services = FakeServices(
      entries: <Entry>[...WorkedExample.entries, ...WorkedExample.insurancePutIns],
      rules: <RecurringRule>[WorkedExample.salary, WorkedExample.rent, ...bills, saving ?? _reachedInsurance],
    );
    await tester.runAsync(loadAppFonts);
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1
      ..displayFeatures = displayFeatures;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(HisaabApp(getIt: services.register(GetIt.asNewInstance())));
    await _settle(tester);
  }

  RecurringRule insurance() => services.recurring.rules.singleWhere((RecurringRule r) => r.id == 5);

  Future<void> useFromSavings(int rupees) => services.ledger
      .addForSaving(
        EntryDraft(amount: Money.fromMajor(rupees), kind: EntryKind.used, categoryId: SeedCategoryIds.saved, date: WorkedExample.today),
        savingId: 5,
      )
      .run();

  testWidgets('a pending saving shows the line at a cold start and writes it as shown (AC-R1, AC-R2)', (WidgetTester tester) async {
    await boot(tester);

    expect(find.text('Insurance reached ₹12,000.'), findsOneWidget);
    expect(insurance().targetReachedFor, Option<Money>.of(_target));
    expect(insurance().targetReachedOn, const Option<CalendarDate>.of(WorkedExample.today));
  });

  testWidgets('it outranks the install line (FR-HO-3 order)', (WidgetTester tester) async {
    await boot(tester);

    expect(find.byType(ReachedLineRow), findsOneWidget);
    expect(find.byType(InstallLineRow), findsNothing);
  });

  testWidgets('in two panes (book) it shows once, in the Home pane (D173)', (WidgetTester tester) async {
    await boot(tester, size: TestWindows.book, displayFeatures: <DisplayFeature>[TestWindows.bookHinge]);

    expect(find.text('Insurance reached ₹12,000.'), findsOneWidget);
    expect(tester.getRect(find.byType(ReachedLineRow)).right, lessThanOrEqualTo(TestWindows.bookHinge.bounds.left));
    expect(services.recurring.updates, hasLength(1));
  });

  testWidgets('a due-soon line holds the slot: no reached line and nothing written (E149)', (WidgetTester tester) async {
    await boot(
      tester,
      saving: _reachedInsurance.copyWith(
        nextDue: const CalendarDate(2026, 10, 29),
        schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 9, 29)),
      ),
      // why: a reached saving is never due soon (D216), so a bill due on the 29th holds the slot.
      bills: <RecurringRule>[WorkedExample.electricity],
    );

    expect(find.byType(DueSoonRow), findsOneWidget);
    expect(find.byType(ReachedLineRow), findsNothing);
    expect(insurance().targetReachedOn, const Option<CalendarDate>.none());
  });

  testWidgets('a tap opens the saving\'s sheet over Home, and the line stays when it closes (AC-R5)', (WidgetTester tester) async {
    await boot(tester);

    await tester.tap(find.byType(ReachedLineRow));
    await _settle(tester);
    expect(find.byType(BillSheet), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await _settle(tester);

    expect(find.byType(BillSheet), findsNothing);
    expect(find.byType(ReachedLineRow), findsOneWidget);
  });

  testWidgets('set aside dropping below the target takes it away at the next reload (F3, E150)', (WidgetTester tester) async {
    await boot(tester);
    expect(find.byType(ReachedLineRow), findsOneWidget);

    await tester.runAsync(() => useFromSavings(5000));
    await _settle(tester);

    expect(find.byType(ReachedLineRow), findsNothing);
  });

  testWidgets('a rename keeps the line, with the new name', (WidgetTester tester) async {
    await boot(tester);

    await tester.runAsync(() => services.recurring.update(insurance().copyWith(label: 'Car insurance')).run());
    await _settle(tester);

    expect(find.text('Car insurance reached ₹12,000.'), findsOneWidget);
  });

  testWidgets('when the line it opened leaves, focus goes to the "Today" heading (AC-R3, T7)', (WidgetTester tester) async {
    await boot(tester);
    await tester.tap(find.byType(ReachedLineRow));
    await _settle(tester);
    await tester.tapAt(const Offset(10, 10));
    await _settle(tester);

    await tester.runAsync(() => useFromSavings(5000));
    await _settle(tester);

    expect(find.byType(ReachedLineRow), findsNothing);
    expect(FocusManager.instance.primaryFocus?.debugLabel, 'Today heading');
  });

  testWidgets('the Savings list names a month of this year without the year (BR-23 "Done by")', (WidgetTester tester) async {
    services = FakeServices(
      entries: <Entry>[...WorkedExample.entries, ...WorkedExample.insurancePutIns],
      rules: <RecurringRule>[WorkedExample.salary, _reachedInsurance.copyWith(target: Option<Money>.of(Money.fromMajor(13000)))],
    );
    await pumpApp(tester, AppRoutes.bills(services.register(GetIt.asNewInstance()), kind: EntryKind.saved));
    await _settle(tester);

    expect(find.text('₹12,000 set aside · done by Nov'), findsOneWidget);
  });
}
