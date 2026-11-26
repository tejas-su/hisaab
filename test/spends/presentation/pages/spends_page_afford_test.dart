import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/presentation/widgets/afford_card.dart';
import 'package:hisaab/spends/presentation/widgets/spends_card.dart';
import 'package:hisaab/spends/spends.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

/// The *Can I afford it?* card on Spends (SPEC FR-SP-9 AC-1, UI_DESIGN 5.4a).
void main() {
  late FakeServices services;
  late SpendsBloc bloc;
  late int affordTaps;

  final Finder afford = find.byKey(const ValueKey<String>('afford-card'));
  final Finder askAi = find.byKey(const ValueKey<String>('ask-ai-card'));

  setUp(() {
    services = FakeServices();
    bloc = services.spendsBloc();
    affordTaps = 0;
  });

  tearDown(() async {
    await bloc.close();
    await services.dispose();
  });

  Future<void> pump(WidgetTester tester, {Size size = TestWindows.phone, double textScale = 1, bool withAfford = true}) async {
    await tester.runAsync(() => bloc.dispatch(const SpendsLoadRequested()));
    await pumpApp(
      tester,
      BlocProvider<SpendsBloc>.value(
        value: bloc,
        child: Scaffold(
          body: SpendsPage(
            today: WorkedExample.today,
            onSeeEntries: (PayCycle _, Option<int> _) {},
            onAskAi: (PayCycle _) {},
            onAfford: withAfford ? () => affordTaps++ : null,
          ),
        ),
      ),
      size: size,
      textScale: textScale,
    );
  }

  Future<void> showSeptember(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const ValueKey<String>('earlier-cycle')));
      await pumpEventQueue();
    });
    await tester.pumpAndSettle();
  }

  void trackSeptember({bool withIncome = true}) {
    services.ledger.entries.addAll(<Entry>[
      if (withIncome)
        Entry(id: 201, amount: Money.fromMajor(45000), kind: EntryKind.got, categoryId: SeedCategoryIds.salary, date: const CalendarDate(2026, 9, 4), createdAt: DateTime(2026, 9, 4)),
      Entry(id: 202, amount: Money.fromMajor(2000), kind: EntryKind.spent, categoryId: SeedCategoryIds.food, date: const CalendarDate(2026, 9, 10), createdAt: DateTime(2026, 9, 10)),
    ]);
  }

  group('SpendsPage Can I afford it? card (FR-SP-9 AC-1)', () {
    testWidgets('shows on the current cycle with income, and opens the check on tap', (WidgetTester tester) async {
      await pump(tester);
      expect(afford, findsOneWidget);
      expect(find.text('Can I afford it?'), findsOneWidget);
      await tester.tap(afford);
      expect(affordTaps, 1);
    });

    testWidgets('shows alone on an empty current cycle, below the sentence, with no Ask AI card', (WidgetTester tester) async {
      services.ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.spent);
      await pump(tester);
      expect(afford, findsOneWidget);
      expect(askAi, findsNothing);
      expect(tester.getTopLeft(afford).dy, greaterThan(tester.getBottomLeft(find.byType(SpendsCard)).dy));
    });

    testWidgets('shows on a past cycle that had income ("on any cycle shown")', (WidgetTester tester) async {
      trackSeptember();
      await pump(tester);
      await showSeptember(tester);
      expect(find.text('September'), findsOneWidget);
      expect(afford, findsOneWidget);
    });

    testWidgets('shows on a past cycle with no income, since income is set up (D223)', (WidgetTester tester) async {
      trackSeptember(withIncome: false);
      await pump(tester);
      await showSeptember(tester);
      expect(find.text('September'), findsOneWidget);
      expect(afford, findsOneWidget);
    });

    testWidgets('It changes: no pay this cycle but pay last month still shows it (D223)', (WidgetTester tester) async {
      services.recurring.rules = <RecurringRule>[];
      services.ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.got);
      trackSeptember();
      await pump(tester);
      expect(afford, findsOneWidget);
    });

    testWidgets('hidden with no income rule and no Got ever', (WidgetTester tester) async {
      services.recurring.rules = <RecurringRule>[];
      services.ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.got);
      await pump(tester);
      expect(askAi, findsOneWidget);
      expect(afford, findsNothing);
    });

    testWidgets('hidden on an empty cycle with no income rule and no Got ever', (WidgetTester tester) async {
      services.recurring.rules = <RecurringRule>[];
      services.ledger.entries.clear();
      await pump(tester);
      expect(afford, findsNothing);
    });

    testWidgets('hidden when no one handles it', (WidgetTester tester) async {
      await pump(tester, withAfford: false);
      expect(afford, findsNothing);
      expect(find.byType(AffordCard), findsNothing);
    });

    testWidgets('a phone stacks it under Ask AI, edge to edge (UI_DESIGN 5.4a: beside it on 600dp and wider)', (WidgetTester tester) async {
      await pump(tester);
      expect(tester.getTopLeft(afford).dy, greaterThanOrEqualTo(tester.getBottomLeft(askAi).dy));
      expect(tester.getTopLeft(afford).dx, tester.getTopLeft(askAi).dx);
      expect(tester.getSize(afford).width, tester.getSize(askAi).width);
    });

    testWidgets('a 320dp phone at 1.5× text stacks it too', (WidgetTester tester) async {
      await pump(tester, size: TestWindows.smallPhone, textScale: 1.5);
      expect(tester.getTopLeft(afford).dy, greaterThanOrEqualTo(tester.getBottomLeft(askAi).dy));
      expect(tester.takeException(), isNull);
    });

    for (final (String name, Size size) in <(String, Size)>[
      ('an unfolded foldable', TestWindows.foldableUnfolded),
      ('a tablet', TestWindows.tablet),
    ]) {
      testWidgets('on $name it sits beside Ask AI, the same height, sharing its edges', (WidgetTester tester) async {
        await pump(tester, size: size);
        expect(tester.getTopLeft(afford).dy, tester.getTopLeft(askAi).dy);
        expect(tester.getTopLeft(afford).dx, greaterThan(tester.getTopRight(askAi).dx));
        expect(tester.getSize(afford).height, tester.getSize(askAi).height);
        expect(tester.getSize(afford).width, tester.getSize(askAi).width);
      });
    }

    testWidgets('large text on a wide window stacks again rather than squeeze', (WidgetTester tester) async {
      await pump(tester, size: TestWindows.foldableUnfolded, textScale: 2);
      expect(tester.getTopLeft(afford).dy, greaterThanOrEqualTo(tester.getBottomLeft(askAi).dy));
    });

    for (final (String name, Size size, double scale) in <(String, Size, double)>[
      ('phone', TestWindows.phone, 1),
      ('phone at 1.5× text', TestWindows.phone, 1.5),
      ('phoneLandscape', TestWindows.phoneLandscape, 1),
      ('smallPhone at 1.5× text', TestWindows.smallPhone, 1.5),
      ('smallPhone at 2× text', TestWindows.smallPhone, 2),
      ('foldableUnfolded', TestWindows.foldableUnfolded, 1),
      ('foldableLandscape', TestWindows.foldableLandscape, 1),
      ('tablet', TestWindows.tablet, 1),
      ('tablet at 1.5× text', TestWindows.tablet, 1.5),
      ('splitScreen', TestWindows.splitScreen, 1),
      ('splitScreenShort', TestWindows.splitScreenShort, 1),
      ('landscape600', TestWindows.landscape600, 1),
      ('tabletop', TestWindows.tabletop, 1),
    ]) {
      testWidgets('nothing overflows on $name', (WidgetTester tester) async {
        await pump(tester, size: size, textScale: scale);
        expect(afford, findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
