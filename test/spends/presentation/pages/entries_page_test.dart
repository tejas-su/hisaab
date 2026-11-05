import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/spends/presentation/widgets/entries_day.dart';
import 'package:expense_tracker/spends/spends.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

const PayCycle _october = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3));

void main() {
  late FakeServices services;
  late EntriesBloc bloc;
  late List<Entry> edited;

  setUp(() {
    services = FakeServices();
    bloc = EntriesBloc(
      cycle: _october,
      ledger: services.ledger,
      categories: services.categories,
      deleteEntry: DeleteEntry(ledger: services.ledger),
      restoreEntry: RestoreEntry(ledger: services.ledger),
      haptics: services.haptics,
    );
    edited = <Entry>[];
  });

  tearDown(() async {
    await bloc.close();
    await services.dispose();
  });

  Future<void> pump(WidgetTester tester, {bool load = true, Size size = TestWindows.phone, double textScale = 1}) async {
    if (load) {
      await tester.runAsync(() => bloc.dispatch(const EntriesLoadRequested()));
    }
    await pumpApp(
      tester,
      BlocProvider<EntriesBloc>.value(
        value: bloc,
        child: EntriesPage(cycle: _october, today: WorkedExample.today, onEdit: edited.add),
      ),
      size: size,
      textScale: textScale,
    );
  }

  group('EntriesPage (FR-SP-6)', () {
    testWidgets('loading shows the title only', (WidgetTester tester) async {
      await pump(tester, load: false);
      expect(find.text('Every entry'), findsOneWidget);
      expect(find.byType(EntriesDay), findsNothing);
    });

    testWidgets('shows the cycle by day, newest first, with each day\'s spending', (WidgetTester tester) async {
      await pump(tester);
      expect(find.text('October'), findsOneWidget);
      expect(find.text('Mon, 26 Oct'), findsOneWidget);
      expect(find.text('₹420'), findsWidgets);
      expect(tester.getTopLeft(find.text('Mon, 26 Oct')).dy, lessThan(tester.getTopLeft(find.text('Tue, 20 Oct')).dy));
    });

    testWidgets('a card bill is listed with its word and left out of the day\'s total (D123)', (WidgetTester tester) async {
      services.ledger.entries.add(Entry(
        id: 81,
        amount: Money.fromMajor(8000),
        kind: EntryKind.cardPaid,
        categoryId: 12,
        date: WorkedExample.today,
        createdAt: WorkedExample.now,
        recurringId: 9,
        note: 'Credit card',
      ));
      await pump(tester);
      expect(find.text('Paid, not counted again'), findsOneWidget);
      expect(find.text('₹420'), findsWidgets);
      expect(find.text('₹8,420'), findsNothing);
    });

    testWidgets('a category chip narrows the list; All brings everything back', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey<String>('filter-travel')));
      await tester.settle();
      expect(find.byType(EntryRow), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('filter-all')));
      await tester.settle();
      expect(find.byType(EntryRow), findsWidgets);
    });

    testWidgets('the header names the active filter, and drops it for All (D89)', (WidgetTester tester) async {
      await pump(tester);
      expect(find.text('· Travel'), findsNothing);
      await tester.tap(find.byKey(const ValueKey<String>('filter-travel')));
      await tester.settle();
      expect(find.text('October'), findsOneWidget);
      expect(find.text('· Travel'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('filter-all')));
      await tester.settle();
      expect(find.text('· Travel'), findsNothing);
    });

    testWidgets('the filters are one row that scrolls sideways, never a second row', (WidgetTester tester) async {
      await pump(tester);
      final Finder row = find.ancestor(of: find.byKey(const ValueKey<String>('filter-all')), matching: find.byType(SingleChildScrollView));
      expect(tester.widget<SingleChildScrollView>(row.first).scrollDirection, Axis.horizontal);
    });

    testWidgets('a chip with nothing left in it says so', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey<String>('filter-travel')));
      await tester.settle();
      await tester.runAsync(() => bloc.dispatch(EntriesDeleteRequested((bloc.state as EntriesReady).shown.single)));
      await tester.pumpAndSettle();
      expect(find.text('Nothing here yet.'), findsOneWidget);
    });

    testWidgets('tapping a row edits it', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.text('Chai & samosa'));
      expect(edited.single.id, 4);
    });

    testWidgets('swiping deletes at once and Undo brings it back (BR-10)', (WidgetTester tester) async {
      await pump(tester);
      await tester.drag(find.text('Chai & samosa'), const Offset(-500, 0));
      await tester.settle();
      expect(find.text('Chai & samosa'), findsNothing);
      expect(find.text('Deleted ₹60'), findsOneWidget);
      expect(services.haptics.events, contains('threshold'));
      await tester.tap(find.text('Undo'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.text('Chai & samosa'), findsOneWidget);
    });

    testWidgets('a swiped row and its Delete stay inside the day card\'s rounded shape', (WidgetTester tester) async {
      await pump(tester);
      final Container card = tester.widget<Container>(
        find.ancestor(of: find.byType(EntryRow).first, matching: find.byType(Container)).first,
      );
      expect(card.clipBehavior, Clip.antiAlias);
    });

    testWidgets('Back pops the page', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('a failed load says so and Try again reloads', (WidgetTester tester) async {
      services.ledger.failure = DatabaseFailure('locked');
      await pump(tester);
      expect(find.text("Couldn't load your money."), findsOneWidget);
      services.ledger.failure = null;
      await tester.runAsync(() async {
        await tester.tap(find.text('Try again'));
        await pumpEventQueue();
      });
      await tester.pumpAndSettle();
      expect(find.byType(EntriesDay), findsWidgets);
    });

    testWidgets('day cards and chips share the page\'s left edge', (WidgetTester tester) async {
      await pump(tester);
      final double edge = tester.getTopLeft(find.byKey(const ValueKey<String>('filter-all'))).dx;
      expect(tester.getTopLeft(find.byType(EntriesDay).first).dx, edge);
      expect(tester.getTopLeft(find.text('October')).dx, edge);
    });

    for (final (String name, Size size, double scale) in <(String, Size, double)>[
      ('a 320dp phone at 2× text', TestWindows.smallPhone, 2),
      ('a phone in landscape', TestWindows.phoneLandscape, 1),
    ]) {
      testWidgets('lays out without overflow on $name', (WidgetTester tester) async {
        await pump(tester, size: size, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets tap-target and label guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });

}
