import 'package:expense_tracker/ask_ai/ask_ai.dart';
import 'package:expense_tracker/add_entry/add_entry.dart';
import 'package:expense_tracker/app/hisaab_app.dart';
import 'package:expense_tracker/app/main_screen.dart';
import 'package:expense_tracker/app/widgets/hisaab_dock.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/home/home.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/spends/spends.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

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
}
