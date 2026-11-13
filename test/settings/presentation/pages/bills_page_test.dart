import 'package:hisaab/core/design/hisaab_dimensions.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/layout/window_class.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/widgets/signal_key.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/presentation/bloc/bills_bloc.dart';
import 'package:hisaab/settings/presentation/bloc/bills_event.dart';
import 'package:hisaab/settings/presentation/pages/bills_page.dart';
import 'package:hisaab/settings/presentation/widgets/bills_list.dart';
import 'package:material_ui/material_ui.dart';
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
      expect(find.text('Bills'), findsOneWidget);
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
      expect(find.textContaining('adds most bills to your spends'), findsOneWidget);
      expect(find.text('Add a bill'), findsNothing);
    });

    testWidgets('Add a bill opens the editor', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey<String>('add-bill')));
      expect(calls, <Object>['add']);
    });

    testWidgets('Add a bill is a marigold key pinned to the bottom, on the card\'s edges (D136)', (WidgetTester tester) async {
      await pump(tester);
      final Finder add = find.byKey(const ValueKey<String>('add-bill'));
      expect(tester.widget(add), isA<SignalKey>());
      expect(tester.getBottomLeft(add).dy, TestWindows.phone.height - HisaabSpacing.l);
      expect(tester.getTopLeft(add).dx, tester.getTopLeft(find.byType(BillsList)).dx);
      expect(tester.getTopRight(add).dx, tester.getTopRight(find.byType(BillsList)).dx);
    });

    testWidgets('a failed load shows no Add key; Try again is the only act', (WidgetTester tester) async {
      recurring.failure = DatabaseFailure('locked');
      await pump(tester);
      expect(find.byKey(const ValueKey<String>('add-bill')), findsNothing);
    });

    testWidgets('the Undo bar sits above the pinned key, never over it', (WidgetTester tester) async {
      await pump(tester);
      await tester.drag(find.text('Rent'), const Offset(-500, 0));
      await tester.settle();
      expect(
        tester.getBottomLeft(find.text('Rent deleted')).dy,
        lessThan(tester.getTopLeft(find.byKey(const ValueKey<String>('add-bill'))).dy),
      );
    });

    testWidgets('on a tablet the list and key share one 560dp column', (WidgetTester tester) async {
      await pump(tester, size: TestWindows.tablet);
      final Rect add = tester.getRect(find.byKey(const ValueKey<String>('add-bill')));
      final Rect card = tester.getRect(find.byType(BillsList));
      expect(add.width, lessThanOrEqualTo(LayoutBreakpoints.singlePaneMaxWidth));
      expect(add.left, card.left);
      expect(add.right, card.right);
      expect(add.center.dx, TestWindows.tablet.width / 2);
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
      expect(find.text('Rent deleted'), findsOneWidget);
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
      expect(find.textContaining('No bills added yet'), findsOneWidget);
      expect(find.text('Add a bill'), findsOneWidget);
    });

    testWidgets('a failed load says so and Try again reloads', (WidgetTester tester) async {
      recurring.failure = DatabaseFailure('locked');
      await pump(tester);
      expect(find.text("Couldn't open this."), findsOneWidget);
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

    void addPostedRd() => ledger.entries.add(
      Entry(
        id: 50,
        amount: Money.fromMajor(5000),
        kind: EntryKind.saved,
        categoryId: SeedCategoryIds.saved,
        date: const CalendarDate(2026, 10, 10),
        createdAt: WorkedExample.now,
        recurringId: 4,
      ),
    );

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

    testWidgets('Put in extra is a chip under the pinned Add a saving, on its edges (D136)', (WidgetTester tester) async {
      await pumpSavings(tester);
      final Rect add = tester.getRect(find.byKey(const ValueKey<String>('add-bill')));
      final Rect putIn = tester.getRect(find.byKey(const ValueKey<String>('put-in-extra')));
      expect(putIn.top, add.bottom + HisaabSpacing.s);
      expect(putIn.bottom, TestWindows.phone.height - HisaabSpacing.l);
      expect((putIn.left, putIn.right), (add.left, add.right));
    });

    testWidgets('in a short window Add a saving and Put in extra share one row', (WidgetTester tester) async {
      await pumpSavings(tester, size: TestWindows.phoneLandscape);
      final Rect add = tester.getRect(find.byKey(const ValueKey<String>('add-bill')));
      final Rect putIn = tester.getRect(find.byKey(const ValueKey<String>('put-in-extra')));
      expect((putIn.top, putIn.bottom), (add.top, add.bottom));
      expect(putIn.left, greaterThan(add.right));
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
  group('BillsPage savings footer (AC-Y4, BR-19)', () {
    late BillsBloc savings;

    Future<void> pumpSavings(
      WidgetTester tester,
      List<Entry> entries, {
      Size size = TestWindows.phone,
      double textScale = 1,
    }) async {
      ledger = FakeLedgerRepository(entries);
      recurring.rules = <RecurringRule>[WorkedExample.insurance];
      savings = BillsBloc(
        getBills: GetBills(recurring: recurring),
        deleteBill: DeleteBill(recurring: recurring),
        restoreBill: RestoreBill(recurring: recurring),
        recurring: recurring,
        haptics: haptics,
        getSavedTotal: GetSavedTotal(ledger: ledger),
        getSetAside: GetSetAside(recurring: recurring, ledger: ledger),
        ledger: ledger,
        kind: EntryKind.saved,
      );
      addTearDown(savings.close);
      await tester.runAsync(() => savings.dispatch(const BillsLoadRequested()));
      await pumpApp(
        tester,
        BlocProvider<BillsBloc>.value(
          value: savings,
          child: BillsPage(kind: EntryKind.saved, onAdd: () {}, onEdit: (RecurringRule _) {}),
        ),
        size: size,
        textScale: textScale,
      );
    }

    Entry used(int rupees) => Entry(
          id: 900,
          amount: Money.fromMajor(rupees),
          kind: EntryKind.used,
          categoryId: SeedCategoryIds.saved,
          date: WorkedExample.today,
          createdAt: WorkedExample.now,
          note: 'Insurance',
          savingId: 5,
        );

    final Finder lineOne = find.byKey(const ValueKey<String>('saved-since'));
    final Finder lineTwo = find.byKey(const ValueKey<String>('still-set-aside'));

    testWidgets('line 1 stays "₹12,000 put in since Nov"; line 2 reads "Nothing is set aside now." after a full use', (WidgetTester tester) async {
      await pumpSavings(tester, <Entry>[...WorkedExample.insurancePutIns, used(12000)]);

      expect(tester.widget<Text>(lineOne).data, '₹12,000 put in since Nov');
      expect(tester.widget<Text>(lineTwo).data, 'Nothing is set aside now.');
    });

    testWidgets('line 2 is absent when nothing is set aside and no use exists', (WidgetTester tester) async {
      await pumpSavings(tester, const <Entry>[]);

      expect(lineTwo, findsNothing);
    });

    testWidgets('line 2 reads "₹4,000 still set aside" with ₹4,000 left', (WidgetTester tester) async {
      await pumpSavings(tester, <Entry>[...WorkedExample.insurancePutIns, used(8000)]);

      expect(tester.widget<Text>(lineTwo).data, '₹4,000 still set aside');
      expect(find.text('₹4,000 set aside'), findsOneWidget);
    });

    testWidgets('TalkBack reads the footer line in rupees', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await pumpSavings(tester, <Entry>[...WorkedExample.insurancePutIns, used(8000)]);

      expect(find.bySemanticsLabel('4,000 rupees still set aside'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a fixed bills list has neither line', (WidgetTester tester) async {
      await pump(tester);

      expect(lineTwo, findsNothing);
      expect(find.textContaining('set aside'), findsNothing);
    });

    testWidgets('at 320 by 568 with 2.0x text the footer wraps and the pinned key stays on screen', (WidgetTester tester) async {
      await pumpSavings(
        tester,
        <Entry>[...WorkedExample.insurancePutIns, used(8000)],
        size: TestWindows.smallPhone,
        textScale: 2,
      );

      expect(tester.takeException(), isNull);
      final Rect key = tester.getRect(find.byKey(const ValueKey<String>('add-bill')));
      expect(key.bottom, lessThanOrEqualTo(TestWindows.smallPhone.height));
      expect(key.top, greaterThanOrEqualTo(0));
      await tester.scrollUntilVisible(lineTwo, 100);
      expect(lineTwo, findsOneWidget);
    });
  });

}
