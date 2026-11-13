import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hisaab/app/hisaab_app.dart';
import 'package:hisaab/app/routes.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/home/home.dart';
import 'package:hisaab/home/presentation/widgets/due_soon_row.dart';
import 'package:hisaab/home/presentation/widgets/hero_card.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_services.dart';
import '../helpers/fixtures/ledger/worked_example.dart';
import '../helpers/pump_app.dart';

/// Insurance with ₹12,000 set aside, due in 3 days, so Home's due-soon line opens its sheet.
RecurringRule get _dueInsurance => WorkedExample.insurance.copyWith(
      nextDue: const CalendarDate(2026, 10, 29),
      schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 9, 29)),
    );

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

Future<void> _tapDigits(WidgetTester tester, String digits) async {
  for (final String digit in digits.split('')) {
    await tester.tap(find.byKey(ValueKey<String>('keypad-$digit')));
    await _settle(tester);
  }
}

void main() {
  late FakeServices services;

  tearDown(() => services.dispose());

  FakeServices savingServices() => FakeServices(
        entries: <Entry>[...WorkedExample.entries, ...WorkedExample.insurancePutIns],
        rules: <RecurringRule>[WorkedExample.salary, WorkedExample.rent, _dueInsurance],
      );

  Future<void> bootHome(WidgetTester tester) async {
    services = savingServices();
    await tester.runAsync(loadAppFonts);
    tester.view
      ..physicalSize = TestWindows.phone
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(HisaabApp(getIt: services.register(GetIt.asNewInstance())));
    await _settle(tester);
  }

  Future<void> useFromSheet(WidgetTester tester, String digits) async {
    await tester.tap(find.byKey(const ValueKey<String>('bill-used')));
    await _settle(tester);
    await _tapDigits(tester, digits);
    await tester.tap(find.byKey(const ValueKey<String>('used-save')));
    await _settle(tester);
  }

  Money heroSafeToday(WidgetTester tester) => tester.widget<HeroCard>(find.byType(HeroCard)).summary.safeToday;

  group('Used from the due-soon door (AC-Y9, E110, NFR-12)', () {
    testWidgets('Save posts the entry, offers the snackbar, and the hero does not move', (WidgetTester tester) async {
      await bootHome(tester);
      final Money before = heroSafeToday(tester);
      await tester.tap(find.byType(DueSoonRow));
      await _settle(tester);

      await useFromSheet(tester, '4000');

      expect(find.byType(BillSheet), findsNothing);
      expect(find.text('Insurance: ₹4,000 used'), findsOneWidget);
      expect(services.ledger.entries.last.kind, EntryKind.used);
      expect(services.ledger.entries.last.savingId, 5);
      expect(heroSafeToday(tester), before);
    });

    testWidgets('the snackbar reads in rupees to TalkBack', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await bootHome(tester);
      await tester.tap(find.byType(DueSoonRow));
      await _settle(tester);

      await useFromSheet(tester, '4000');

      expect(find.bySemanticsLabel('Insurance: 4,000 rupees used'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Undo deletes the entry and does not reopen the sheet', (WidgetTester tester) async {
      await bootHome(tester);
      await tester.tap(find.byType(DueSoonRow));
      await _settle(tester);
      await useFromSheet(tester, '4000');

      await tester.tap(find.text('Undo'));
      await _settle(tester);

      expect(services.ledger.entries.where((Entry e) => e.kind == EntryKind.used), isEmpty);
      expect(find.byType(BillSheet), findsNothing);
    });

    testWidgets('Home holds its numbers while the saving sheet is open and reloads once it has closed', (WidgetTester tester) async {
      await bootHome(tester);
      final HomeBloc home = tester.element(find.byType(HomePage)).read<HomeBloc>();
      await tester.tap(find.byType(DueSoonRow));
      await _settle(tester);
      final int before = (home.state as HomeReady).todayEntries.length;

      await services.ledger
          .addForSaving(
            EntryDraft(
              amount: Money.fromMajor(100),
              kind: EntryKind.used,
              categoryId: 11,
              date: WorkedExample.today,
              note: 'Insurance',
            ),
            savingId: 5,
          )
          .run();
      await _settle(tester);
      expect((home.state as HomeReady).todayEntries, hasLength(before));

      Navigator.of(tester.element(find.byType(BillSheet))).pop();
      await _settle(tester);

      expect((home.state as HomeReady).todayEntries, hasLength(before + 1));
    });
  });

  group('Used from the Savings list (AC-Y9)', () {
    Future<void> openList(WidgetTester tester) async {
      services = savingServices();
      final GetIt getIt = services.register(GetIt.asNewInstance());
      await pumpApp(tester, AppRoutes.bills(getIt, kind: EntryKind.saved));
      await _settle(tester);
    }

    testWidgets('the snackbar reads "Insurance: ₹4,000 used"; the list shows what is left; no hold is sent', (WidgetTester tester) async {
      await openList(tester);
      expect(find.text('₹12,000 set aside'), findsOneWidget);
      await tester.tap(find.text('Insurance'));
      await _settle(tester);

      await useFromSheet(tester, '4000');

      expect(find.text('Insurance: ₹4,000 used'), findsOneWidget);
      expect(find.text('₹8,000 set aside'), findsOneWidget);
      expect(find.text('₹8,000 still set aside'), findsOneWidget);
    });

    testWidgets('Undo deletes the entry, sets the money aside again and does not reopen the sheet', (WidgetTester tester) async {
      await openList(tester);
      await tester.tap(find.text('Insurance'));
      await _settle(tester);
      await useFromSheet(tester, '4000');

      await tester.tap(find.text('Undo'));
      await _settle(tester);

      expect(services.ledger.entries.where((Entry e) => e.kind == EntryKind.used), isEmpty);
      expect(find.text('₹12,000 set aside'), findsOneWidget);
      expect(find.byType(BillSheet), findsNothing);
    });

    testWidgets('deleting a saving that has had a put-in says what stays', (WidgetTester tester) async {
      await openList(tester);
      await tester.tap(find.text('Insurance'));
      await _settle(tester);
      await tester.ensureVisible(find.byKey(const ValueKey<String>('bill-delete')));
      await tester.tap(find.byKey(const ValueKey<String>('bill-delete')));
      await _settle(tester);

      expect(find.text('Insurance deleted. What you put in stays in your history.'), findsOneWidget);
    });

    testWidgets('deleting a saving with no put-in says only that it is deleted', (WidgetTester tester) async {
      services = FakeServices(
        entries: WorkedExample.entries,
        rules: <RecurringRule>[WorkedExample.salary, WorkedExample.insurance],
      );
      await pumpApp(tester, AppRoutes.bills(services.register(GetIt.asNewInstance()), kind: EntryKind.saved));
      await _settle(tester);
      await tester.tap(find.text('Insurance'));
      await _settle(tester);
      await tester.ensureVisible(find.byKey(const ValueKey<String>('bill-delete')));
      await tester.tap(find.byKey(const ValueKey<String>('bill-delete')));
      await _settle(tester);

      expect(find.text('Insurance deleted'), findsOneWidget);
    });
  });
}
