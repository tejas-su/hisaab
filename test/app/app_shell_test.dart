import 'dart:ui';

import 'package:expense_tracker/app/app_shell.dart';
import 'package:expense_tracker/app/widgets/hisaab_dock.dart';
import 'package:expense_tracker/home/home.dart';
import 'package:expense_tracker/spends/spends.dart';
import 'package:expense_tracker/core/time/pay_cycle.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../helpers/fake_services.dart';
import '../helpers/fixtures/ledger/worked_example.dart';
import '../helpers/pump_app.dart';

late FakeServices _services;

Widget _shell() => MultiBlocProvider(
      providers: <BlocProvider<Object?>>[
        BlocProvider<HomeBloc>(create: (BuildContext _) => _services.homeBloc()..add(const HomeLoadRequested())),
        BlocProvider<SpendsBloc>(create: (BuildContext _) => _services.spendsBloc()..add(const SpendsLoadRequested())),
      ],
      child: Scaffold(
        body: AppShell(
          home: HomePage(onAdd: (EntryKind _) {}, onEdit: (Entry _) {}, onOpenSettings: () {}, onOpenBill: (RecurringRule _) {}, onEnterBill: (Occurrence _) {}),
          spends: SpendsPage(today: WorkedExample.today, onSeeEntries: (PayCycle _, Option<int> _) {}, onAskAi: (PayCycle _) {}),
          onAdd: () {},
        ),
      ),
    );

DisplayFeature _fold(Rect bounds, DisplayFeatureState state) =>
    DisplayFeature(bounds: bounds, type: DisplayFeatureType.fold, state: state);

void main() {
  setUp(() => _services = FakeServices());
  tearDown(() => _services.dispose());

  group('AppShell adapts to the window (UI_DESIGN §13)', () {
    testWidgets('phone: one screen at a time with the dock', (WidgetTester tester) async {
      await pumpApp(tester, _shell());
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(SpendsPage), findsNothing);
      expect(find.byType(HisaabDock), findsOneWidget);
    });

    testWidgets('phone: the dock switches to Spends and back', (WidgetTester tester) async {
      await pumpApp(tester, _shell());
      Finder dockItem(String label) =>
          find.descendant(of: find.byType(HisaabDock), matching: find.bySemanticsLabel(label));
      await tester.tap(dockItem('Spends'));
      await tester.pumpAndSettle();
      expect(find.byType(SpendsPage), findsOneWidget);
      expect(find.byType(HomePage), findsNothing);

      await tester.tap(dockItem('Home'));
      await tester.pumpAndSettle();
      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('phone: the screen ends at the dock, which keeps its own height (D82)', (WidgetTester tester) async {
      await pumpApp(tester, _shell());
      final Rect dock = tester.getRect(find.byType(HisaabDock));
      expect(tester.getRect(find.byType(HomePage)).bottom, dock.top - 8);
      // why: a dock that fills a loose constraint would cover the whole screen.
      expect(dock.height, lessThan(100));
    });

    testWidgets('phone: the last card scrolls clear of the bottom fade', (WidgetTester tester) async {
      await pumpApp(tester, _shell());
      await tester.tap(find.descendant(of: find.byType(HisaabDock), matching: find.bySemanticsLabel('Spends')));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -2000));
      await tester.pumpAndSettle();
      final Finder last = find.byKey(const ValueKey<String>('see-every-entry'));
      expect(tester.getRect(last).bottom, lessThanOrEqualTo(tester.getRect(find.byKey(const ValueKey<String>('bottom-fade'))).top));
    });

    testWidgets('unfolded foldable portrait: a centred column no wider than 560 dp', (WidgetTester tester) async {
      await pumpApp(tester, _shell(), size: TestWindows.foldableUnfolded);
      final Rect home = tester.getRect(find.byType(HomePage));
      expect(home.width, lessThanOrEqualTo(560));
      expect(home.center.dx, closeTo(TestWindows.foldableUnfolded.width / 2, 0.5));
    });

    testWidgets('tablet: Home beside Spends, no dock', (WidgetTester tester) async {
      await pumpApp(tester, _shell(), size: TestWindows.tablet);
      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(SpendsPage), findsOneWidget);
      expect(find.byType(HisaabDock), findsNothing);
      expect(tester.getRect(find.byType(HomePage)).right, lessThanOrEqualTo(tester.getRect(find.byType(SpendsPage)).left));
    });

    testWidgets('book posture: nothing straddles the vertical fold', (WidgetTester tester) async {
      await pumpApp(
        tester,
        _shell(),
        size: TestWindows.foldableLandscape,
        displayFeatures: <DisplayFeature>[
          _fold(const Rect.fromLTRB(420, 0, 420, 701), DisplayFeatureState.postureHalfOpened),
        ],
      );
      expect(tester.getRect(find.byType(HomePage)).right, lessThanOrEqualTo(420));
      expect(tester.getRect(find.byType(SpendsPage)).left, greaterThanOrEqualTo(420));
    });

    testWidgets('tabletop posture: the screen above the fold, the dock below it', (WidgetTester tester) async {
      await pumpApp(
        tester,
        _shell(),
        size: const Size(701, 841),
        displayFeatures: <DisplayFeature>[
          _fold(const Rect.fromLTRB(0, 420, 701, 420), DisplayFeatureState.postureHalfOpened),
        ],
      );
      expect(tester.getRect(find.byType(HomePage)).bottom, lessThanOrEqualTo(420));
      expect(tester.getRect(find.byType(HisaabDock)).top, greaterThanOrEqualTo(420));
    });

    testWidgets('phone landscape lays out two panes without overflow', (WidgetTester tester) async {
      await pumpApp(tester, _shell(), size: TestWindows.phoneLandscape);
      expect(find.byType(SpendsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('small phone at 2× text size does not overflow', (WidgetTester tester) async {
      await pumpApp(tester, _shell(), size: TestWindows.smallPhone, textScale: 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('dark theme renders', (WidgetTester tester) async {
      await pumpApp(tester, _shell(), themeMode: ThemeMode.dark);
      expect(tester.takeException(), isNull);
      expect(find.byType(HomePage), findsOneWidget);
    });
  });

  group('AppShell accessibility', () {
    testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _shell());
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('the selected dock item is announced as selected', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, _shell());
      expect(
        tester.getSemantics(find.descendant(of: find.byType(HisaabDock), matching: find.bySemanticsLabel('Home'))),
        matchesSemantics(label: 'Home', isButton: true, isSelected: true, hasSelectedState: true, hasTapAction: true),
      );
      handle.dispose();
    });
  });
}
