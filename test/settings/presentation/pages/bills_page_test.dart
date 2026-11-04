import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/settings/presentation/bloc/bills_bloc.dart';
import 'package:expense_tracker/settings/presentation/bloc/bills_event.dart';
import 'package:expense_tracker/settings/presentation/pages/bills_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_haptics.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeRecurringRepository recurring;
  late FakeHaptics haptics;
  late BillsBloc bloc;
  late List<Object> calls;
  late FakeLedgerRepository ledger;

  setUp(() {
    ledger = FakeLedgerRepository(WorkedExample.entries);
    recurring = FakeRecurringRepository(WorkedExample.rules);
    haptics = FakeHaptics();
    bloc = BillsBloc(
      getBills: GetBills(recurring: recurring),
      deleteBill: DeleteBill(recurring: recurring),
      restoreBill: RestoreBill(recurring: recurring),
      recurring: recurring,
      haptics: haptics,
      getSavedTotal: GetSavedTotal(ledger: ledger),
      ledger: ledger,
    );
    calls = <Object>[];
  });

  tearDown(() async {
    await bloc.close();
    await recurring.dispose();
  });

  Future<void> pump(WidgetTester tester, {bool load = true, Size size = TestWindows.phone, double textScale = 1}) async {
    if (load) {
      await tester.runAsync(() => bloc.dispatch(const BillsLoadRequested()));
    }
    await pumpApp(
      tester,
      BlocProvider<BillsBloc>.value(
        value: bloc,
        child: BillsPage(onAdd: () => calls.add('add'), onEdit: (RecurringRule bill) => calls.add(bill)),
      ),
      size: size,
      textScale: textScale,
    );
  }

  group('BillsPage (FR-SE-1)', () {
    testWidgets('lists the bills soonest first, with day and amount', (WidgetTester tester) async {
      await pump(tester);
      expect(find.text('Fixed bills'), findsOneWidget);
      expect(find.text('Every month on day 29'), findsOneWidget);
      expect(find.text('₹1,200'), findsOneWidget);
      expect(find.text('₹8,200'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Electricity')).dy, lessThan(tester.getTopLeft(find.text('Rent')).dy));
      expect(find.text('Salary'), findsNothing);
    });

    testWidgets('TalkBack reads each bill as one sentence', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      expect(find.bySemanticsLabel('Electricity, 1,200 rupees, Every month on day 29'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('loading shows only the hint', (WidgetTester tester) async {
      await pump(tester, load: false);
      expect(find.textContaining('go out by themselves'), findsOneWidget);
      expect(find.text('Add a bill'), findsNothing);
    });

    testWidgets('Add a bill opens the editor', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey<String>('add-bill')));
      expect(calls, <Object>['add']);
    });

    testWidgets('tapping a bill edits it', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.text('Rent'));
      expect(calls, <Object>[WorkedExample.rent]);
    });

    testWidgets('swiping deletes at once and Undo brings it back', (WidgetTester tester) async {
      await pump(tester);
      await tester.drag(find.text('Rent'), const Offset(-500, 0));
      await tester.settle();
      expect(find.text('Rent'), findsNothing);
      expect(find.text('Deleted Rent'), findsOneWidget);
      expect(haptics.events, contains('threshold'));
      await tester.tap(find.text('Undo'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.text('Rent'), findsOneWidget);
    });

    testWidgets('TalkBack users can delete a bill without swiping', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      final SemanticsNode row = tester.getSemantics(find.bySemanticsLabel(RegExp('^Rent, ')));
      expect(row.getSemanticsData().customSemanticsActionIds, isNotEmpty);
      handle.dispose();
    });

    testWidgets('no bills says what to add', (WidgetTester tester) async {
      recurring.rules = <RecurringRule>[WorkedExample.salary];
      await pump(tester);
      expect(find.textContaining('No fixed bills yet'), findsOneWidget);
      expect(find.text('Add a bill'), findsOneWidget);
    });

    testWidgets('a failed load says so and Try again reloads', (WidgetTester tester) async {
      recurring.failure = DatabaseFailure('locked');
      await pump(tester);
      expect(find.text("Couldn't load your money."), findsOneWidget);
      recurring.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.text('Electricity'), findsOneWidget);
    });

    for (final (String name, Size size, double scale) in <(String, Size, double)>[
      ('a 320dp phone at 2× text', TestWindows.smallPhone, 2),
      ('a phone in landscape', TestWindows.phoneLandscape, 1),
      ('a tablet', TestWindows.tablet, 1),
    ]) {
      testWidgets('lays out without overflow on $name', (WidgetTester tester) async {
        await pump(tester, size: size, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  group('BillsPage for savings (D120)', () {
    late BillsBloc savings;

    setUp(() {
      recurring.rules = <RecurringRule>[...WorkedExample.rules, WorkedExample.rd];
      savings = BillsBloc(
        getBills: GetBills(recurring: recurring),
        deleteBill: DeleteBill(recurring: recurring),
        restoreBill: RestoreBill(recurring: recurring),
        recurring: recurring,
        haptics: haptics,
        getSavedTotal: GetSavedTotal(ledger: ledger),
        ledger: ledger,
        kind: EntryKind.saved,
      );
    });

    tearDown(() => savings.close());

    Future<void> pumpSavings(WidgetTester tester, {Size size = TestWindows.phone}) async {
      await tester.runAsync(() => savings.dispatch(const BillsLoadRequested()));
      await pumpApp(
        tester,
        BlocProvider<BillsBloc>.value(
          value: savings,
          child: BillsPage(
            kind: EntryKind.saved,
            onAdd: () => calls.add('add'),
            onEdit: (RecurringRule rule) => calls.add(rule),
            onPutInExtra: () => calls.add('put-in'),
          ),
        ),
        size: size,
      );
    }

    void addPostedRd() => ledger.entries.add(Entry(
          id: 50,
          amount: Money.fromMajor(5000),
          kind: EntryKind.saved,
          categoryId: SeedCategoryIds.saved,
          date: const CalendarDate(2026, 10, 10),
          createdAt: WorkedExample.now,
          recurringId: 4,
        ));

    testWidgets('the Savings list: title, add, rows, footer, Put in extra', (WidgetTester tester) async {
      addPostedRd();
      await pumpSavings(tester);
      expect(find.text('Savings'), findsOneWidget);
      expect(find.text('Add a saving'), findsOneWidget);
      expect(find.text('RD'), findsOneWidget);
      expect(find.text('₹5,000 put in since Oct'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('put-in-extra')));
      expect(calls, <Object>['put-in']);
    });

    testWidgets('no saves yet: no footer', (WidgetTester tester) async {
      await pumpSavings(tester);
      expect(find.textContaining('put in since'), findsNothing);
    });

    for (final Size size in <Size>[
      TestWindows.phone,
      TestWindows.phoneLandscape,
      TestWindows.smallPhone,
      TestWindows.foldableUnfolded,
      TestWindows.foldableLandscape,
      TestWindows.tablet,
    ]) {
      testWidgets('the Savings list fits ${size.width.toInt()}×${size.height.toInt()}', (WidgetTester tester) async {
        addPostedRd();
        await pumpSavings(tester, size: size);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
