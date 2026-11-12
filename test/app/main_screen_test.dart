import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart' show Option;
import 'package:hisaab/ask_ai/ask_ai.dart';
import 'package:hisaab/add_entry/add_entry.dart';
import 'package:hisaab/app/hisaab_app.dart';
import 'package:hisaab/app/main_screen.dart';
import 'package:hisaab/app/widgets/hisaab_dock.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/pay_cycle.dart';
import 'package:hisaab/home/home.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/spends/spends.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

import '../helpers/bloc_dispatch.dart';
import '../helpers/fake_services.dart';
import '../helpers/fixtures/ledger/worked_example.dart';
import '../helpers/pump_app.dart';

void main() {
  late FakeServices services;

  setUp(() => services = FakeServices());
  tearDown(() => services.dispose());

  Future<void> boot(WidgetTester tester, {Size size = TestWindows.phone}) async {
    await tester.runAsync(loadAppFonts);
    tester.view
      ..physicalSize = size
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(HisaabApp(getIt: services.register(GetIt.asNewInstance())));
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
  }

  Future<void> tapAndLoad(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    // why: ensureVisible scrolls without a frame; the tap must hit the scrolled position.
    await tester.pump();
    await tester.tap(target);
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
  }

  Future<void> overspend() =>
      services.ledger.add(EntryDraft(amount: Money.fromMajor(2450), kind: EntryKind.spent, categoryId: 3, date: WorkedExample.today)).run();

  Finder dock(String label) => find.descendant(of: find.byType(HisaabDock), matching: find.bySemanticsLabel(label));

  group('MainScreen (FR-HO-4, FR-HO-5, FR-SP)', () {
    testWidgets('the dock shows Spends with the current cycle', (WidgetTester tester) async {
      await boot(tester);
      await tapAndLoad(tester, dock('Spends'));
      expect(find.byType(SpendsPage), findsOneWidget);
      expect(find.text('October'), findsOneWidget);
    });

    testWidgets('Home\'s See all opens every entry of the cycle; a row there opens the Add tray', (WidgetTester tester) async {
      await boot(tester);
      await tapAndLoad(tester, find.byKey(const ValueKey<String>('see-all')));
      expect(find.byType(EntriesPage), findsOneWidget);
      await tapAndLoad(tester, find.text('Tue, 20 Oct'));
      await tapAndLoad(tester, find.byType(EntryRow).first);
      expect(find.byType(AddEntryTray), findsOneWidget);
    });

    testWidgets('Spends\' See every entry opens the entries page', (WidgetTester tester) async {
      await boot(tester);
      await tapAndLoad(tester, dock('Spends'));
      await tapAndLoad(tester, find.byKey(const ValueKey<String>('see-every-entry')));
      expect(find.byType(EntriesPage), findsOneWidget);
    });

    testWidgets('Spends\' Ask AI card opens Ask AI for the shown cycle', (WidgetTester tester) async {
      await boot(tester);
      await tapAndLoad(tester, dock('Spends'));
      await tapAndLoad(tester, find.byKey(const ValueKey<String>('ask-ai-card')));
      expect(find.byType(AskAiPage), findsOneWidget);
      await tester.scrollUntilVisible(find.text('What the AI will see · 6 entries'), 200, scrollable: find.byType(Scrollable).last);
      expect(find.text('What the AI will see · 6 entries'), findsOneWidget);
    });

    testWidgets('over today, See where it went switches to Spends', (WidgetTester tester) async {
      await overspend();
      await boot(tester);
      await tapAndLoad(tester, find.byKey(const ValueKey<String>('see-where-it-went')));
      expect(find.byType(SpendsPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets('on a tablet Spends is already beside Home, so the step is hidden', (WidgetTester tester) async {
      await overspend();
      await boot(tester, size: TestWindows.tablet);
      expect(find.byType(SpendsPage), findsOneWidget);
      expect(find.textContaining('It happens.'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('see-where-it-went')), findsNothing);
    });

    testWidgets('resuming reloads Spends too', (WidgetTester tester) async {
      await boot(tester);
      await tapAndLoad(tester, dock('Spends'));
      services.ledger.entries.add(
        Entry(
          id: 99,
          amount: Money.fromMajor(1000),
          kind: EntryKind.spent,
          categoryId: 1,
          date: WorkedExample.today,
          createdAt: WorkedExample.now,
        ),
      );
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      expect(find.textContaining('₹28,570'), findsOneWidget);
      expect(find.byType(MainScreen), findsOneWidget);
    });
  });

  group('MainScreen wrapPrimary (BR-10: over whichever of Home or Spends is in view)', () {
    final Finder wrapped = find.byKey(const ValueKey<String>('wrapped'));

    Future<void> pumpMain(
      WidgetTester tester, {
      bool wrap = true,
      Size size = TestWindows.phone,
      List<DisplayFeature> displayFeatures = const <DisplayFeature>[],
    }) async {
      final HomeBloc home = await tester.buildBloc(() => services.homeBloc()..add(const HomeLoadRequested()));
      final SpendsBloc spends = await tester.buildBloc(() => services.spendsBloc()..add(const SpendsLoadRequested()));
      addTearDown(home.close);
      addTearDown(spends.close);
      await tester.runAsync(pumpEventQueue);
      await pumpApp(
        tester,
        MultiBlocProvider(
          providers: <BlocProvider<dynamic>>[
            BlocProvider<HomeBloc>.value(value: home),
            BlocProvider<SpendsBloc>.value(value: spends),
          ],
          child: MainScreen(
            clock: services.clock,
            onAdd: (EntryKind _) {},
            onEdit: (Entry _) {},
            onOpenSettings: () {},
            onOpenBill: (RecurringRule _) {},
            onEnterBill: (Occurrence _) {},
            onSeeEntries: (PayCycle _, Option<int> _) {},
            onAskAi: (PayCycle _) {},
            wrapPrimary: wrap ? (Widget page) => KeyedSubtree(key: const ValueKey<String>('wrapped'), child: page) : null,
          ),
        ),
        size: size,
        displayFeatures: displayFeatures,
      );
    }

    Finder inWrapper(Type page) => find.descendant(of: wrapped, matching: find.byType(page));

    testWidgets('without wrapPrimary nothing changes', (WidgetTester tester) async {
      await pumpMain(tester, wrap: false);
      expect(wrapped, findsNothing);
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('on a phone the page in view is wrapped', (WidgetTester tester) async {
      await pumpMain(tester);
      expect(wrapped, findsOneWidget);
      expect(inWrapper(HomePage), findsOneWidget);
      expect(tester.getRect(wrapped), tester.getRect(find.byType(HomePage)));
    });

    testWidgets('on the Spends tab the wrapper is around Spends', (WidgetTester tester) async {
      await pumpMain(tester);
      await tester.tap(dock('Spends'));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      expect(wrapped, findsOneWidget);
      expect(inWrapper(SpendsPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);
    });

    testWidgets('in two panes only Home is wrapped', (WidgetTester tester) async {
      await pumpMain(tester, size: TestWindows.tablet);
      expect(wrapped, findsOneWidget);
      expect(inWrapper(HomePage), findsOneWidget);
      expect(find.byType(SpendsPage), findsOneWidget);
      expect(inWrapper(SpendsPage), findsNothing);
    });

    testWidgets('on a tabletop the page above the fold is wrapped', (WidgetTester tester) async {
      await pumpMain(
        tester,
        size: const Size(701, 841),
        displayFeatures: const <DisplayFeature>[
          DisplayFeature(
            bounds: Rect.fromLTRB(0, 420, 701, 420),
            type: DisplayFeatureType.fold,
            state: DisplayFeatureState.postureHalfOpened,
          ),
        ],
      );
      expect(wrapped, findsOneWidget);
      expect(inWrapper(HomePage), findsOneWidget);
      expect(tester.getRect(wrapped).bottom, lessThanOrEqualTo(420));
      await tester.tap(dock('Spends'));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      expect(wrapped, findsOneWidget);
      expect(inWrapper(SpendsPage), findsOneWidget);
      expect(tester.getRect(wrapped).bottom, lessThanOrEqualTo(420));
    });
  });
}
