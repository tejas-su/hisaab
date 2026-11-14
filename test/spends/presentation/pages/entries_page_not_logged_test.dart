import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/presentation/widgets/entries_day.dart';
import 'package:hisaab/spends/spends.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/ledger/not_logged.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

const PayCycle _october = PayCycle(start: CalendarDate(2026, 10, 4), end: CalendarDate(2026, 11, 3));

/// Every entry with a *Not logged* fix (SPEC FR-SP-6, D187, NFR-11).
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

  Future<void> pump(WidgetTester tester, {Size size = TestWindows.phone, double textScale = 1}) async {
    await tester.runAsync(() => bloc.dispatch(const EntriesLoadRequested()));
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

  group('EntriesPage a Not logged entry', () {
    testWidgets('is listed with its title, direction and the extra line, and left out of the day total', (WidgetTester tester) async {
      services.ledger.entries.add(notLogged(4200, WorkedExample.today));

      await pump(tester);

      expect(find.text('Not logged'), findsOneWidget);
      expect(find.text('Spent'), findsOneWidget);
      expect(find.text('Added when you fixed your number.'), findsOneWidget);
      expect(find.text('₹4,200'), findsOneWidget);
      expect(find.text('₹420'), findsWidgets);
      expect(find.text('₹4,620'), findsNothing);
    });

    testWidgets('a Got fix says Got and adds nothing to a spent total', (WidgetTester tester) async {
      services.ledger.entries.add(notLogged(1000, WorkedExample.today, got: true));

      await pump(tester);

      expect(find.text('Got'), findsOneWidget);
      expect(find.text('₹1,000'), findsOneWidget);
    });

    testWidgets('a fix posted now is on top of its day', (WidgetTester tester) async {
      services.ledger.entries.add(notLogged(4200, WorkedExample.today, id: 900));

      await pump(tester);

      final double fix = tester.getTopLeft(find.text('Not logged')).dy;
      expect(fix < tester.getTopLeft(find.text('Auto to office')).dy, isTrue);
    });

    testWidgets('has no chip; it shows under All, and a category chip leaves it out', (WidgetTester tester) async {
      services.ledger.entries.add(notLogged(4200, WorkedExample.today));
      await pump(tester);
      expect(find.byKey(const ValueKey<String>('filter-not_logged')), findsNothing);
      expect(find.byKey(const ValueKey<String>('filter-not_logged_in')), findsNothing);

      await tester.tap(find.byKey(const ValueKey<String>('filter-travel')));
      await tester.settle();

      expect(find.text('Not logged'), findsNothing);
    });

    testWidgets('tapping it does not edit', (WidgetTester tester) async {
      services.ledger.entries.add(notLogged(4200, WorkedExample.today));
      await pump(tester);

      await tester.tap(find.text('Not logged'));

      expect(edited, isEmpty);
    });

    testWidgets('Delete is exposed as a custom action, with Undo after it (NFR-11)', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      services.ledger.entries.add(notLogged(4200, WorkedExample.today));
      await pump(tester);
      final SemanticsNode node = tester.getSemantics(find.bySemanticsLabel(RegExp('Not logged. Spent 4,200 rupees')));
      final List<CustomSemanticsAction> actions = <CustomSemanticsAction>[
        for (final int id in node.getSemanticsData().customSemanticsActionIds ?? const <int>[]) ?CustomSemanticsAction.getAction(id),
      ];
      final CustomSemanticsAction delete = actions.firstWhere((CustomSemanticsAction a) => a.label == 'Delete');

      tester.semantics.performAction(find.semantics.byLabel(RegExp('Not logged. Spent 4,200 rupees')), SemanticsAction.customAction, args: CustomSemanticsAction.getIdentifier(delete));
      await tester.settle();

      expect(services.ledger.entries.where((Entry e) => e.isNotLogged), isEmpty);
      expect(find.text('Undo'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('lays out at every window size with no overflow, at 1x and 2x text', (WidgetTester tester) async {
      services.ledger.entries.add(notLogged(4200, WorkedExample.today));
      for (final Size size in <Size>[
        TestWindows.phone,
        TestWindows.smallPhone,
        TestWindows.splitScreen,
        TestWindows.phoneLandscape,
        TestWindows.book,
        TestWindows.tablet,
      ]) {
        for (final double scale in <double>[1, 2]) {
          await pump(tester, size: size, textScale: scale);

          expect(tester.takeException(), isNull, reason: '$size at ${scale}x');
          expect(find.byType(EntriesDay), findsWidgets);
        }
      }
    });
  });
}
