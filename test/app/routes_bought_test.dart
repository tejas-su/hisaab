import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:hisaab/app/hisaab_app.dart';
import 'package:hisaab/app/routes.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/home/presentation/widgets/reached_line_row.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_services.dart';
import '../helpers/fixtures/ledger/worked_example.dart';
import '../helpers/pump_app.dart';

/// Insurance with ₹12,000 set aside and a target of ₹12,000, next put-in in 3 days. It is reached,
/// so Home shows its reached line (never a due-soon row, D216), which opens its reached sheet.
RecurringRule get _reachedInsurance => WorkedExample.insurance.copyWith(
      nextDue: const CalendarDate(2026, 10, 29),
      schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 9, 29)),
      target: Option<Money>.of(Money.fromMajor(12000)),
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

/// *I bought it* closes the saving's sheet, and the screen that opened it offers one Undo that
/// restores the saving and the money set aside (SPEC FR-SE-1 AC-T9, E152, D213).
void main() {
  late FakeServices services;

  tearDown(() => services.dispose());

  FakeServices reachedServices() => FakeServices(
        entries: <Entry>[...WorkedExample.entries, ...WorkedExample.insurancePutIns],
        rules: <RecurringRule>[WorkedExample.salary, WorkedExample.rent, _reachedInsurance],
      );

  Future<void> tapBought(WidgetTester tester) async {
    final Finder bought = find.byKey(const ValueKey<String>('bill-bought'));
    await tester.ensureVisible(bought);
    await tester.tap(bought);
    await _settle(tester);
  }

  group('from the Savings list', () {
    Future<void> openList(WidgetTester tester) async {
      services = reachedServices();
      await pumpApp(tester, AppRoutes.bills(services.register(GetIt.asNewInstance()), kind: EntryKind.saved));
      await _settle(tester);
      await tester.tap(find.text('Insurance'));
      await _settle(tester);
    }

    testWidgets('the sheet closes, the saving leaves the list and the snackbar says "Used ₹12,000 from Insurance"', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await openList(tester);

      await tapBought(tester);

      expect(find.byType(BillSheet), findsNothing);
      expect(find.text('Used ₹12,000 from Insurance'), findsOneWidget);
      expect(find.bySemanticsLabel('Used 12,000 rupees from Insurance'), findsOneWidget);
      expect(find.text('Insurance'), findsNothing);
      handle.dispose();
    });

    testWidgets('Undo brings the saving back with its money set aside, and its target', (WidgetTester tester) async {
      await openList(tester);
      await tapBought(tester);

      await tester.tap(find.text('Undo'));
      await _settle(tester);

      expect(find.text('Insurance'), findsOneWidget);
      expect(services.ledger.entries.where((Entry e) => e.kind == EntryKind.used), isEmpty);
      expect(services.recurring.rules.singleWhere((RecurringRule r) => r.id == 5).target, Option<Money>.of(Money.fromMajor(12000)));
      expect(find.byType(BillSheet), findsNothing);
    });
  });

  group('from Home', () {
    Future<void> bootHome(WidgetTester tester) async {
      services = reachedServices();
      await tester.runAsync(loadAppFonts);
      tester.view
        ..physicalSize = TestWindows.phone
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(HisaabApp(getIt: services.register(GetIt.asNewInstance())));
      await _settle(tester);
      await tester.tap(find.byType(ReachedLineRow));
      await _settle(tester);
    }

    testWidgets('the snackbar shows on Home', (WidgetTester tester) async {
      await bootHome(tester);

      await tapBought(tester);

      expect(find.byType(BillSheet), findsNothing);
      expect(find.text('Used ₹12,000 from Insurance'), findsOneWidget);
    });

    testWidgets('Undo restores the saving and deletes the Used entry', (WidgetTester tester) async {
      await bootHome(tester);
      await tapBought(tester);

      await tester.tap(find.text('Undo'));
      await _settle(tester);

      expect(services.recurring.rules.map((RecurringRule r) => r.id), contains(5));
      expect(services.ledger.entries.where((Entry e) => e.kind == EntryKind.used), isEmpty);
    });
  });
}
