import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Option;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:hisaab/add_entry/add_entry.dart';
import 'package:hisaab/app/hisaab_app.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/home/home.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/onboarding/onboarding.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:hisaab/shortcuts/shortcuts.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_services.dart';
import '../helpers/fixtures/habits/chai_habit.dart';
import '../helpers/fixtures/ledger/worked_example.dart';
import '../helpers/pump_app.dart';

/// Widget, tile and app-shortcut taps through the whole app (SPEC FR-WG-4, FR-WG-6, FR-WG-7,
/// widget spec §8), and when the app writes the widget's snapshot (§7).
void main() {
  late FakeServices services;
  const ValueKey<String> pillKey = ValueKey<String>('usual-pill');

  tearDown(() => services.dispose());

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  Future<void> boot(WidgetTester tester, FakeServices fakes) async {
    services = fakes;
    await tester.runAsync(loadAppFonts);
    tester.view
      ..physicalSize = TestWindows.phone
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(HisaabApp(getIt: fakes.register(GetIt.asNewInstance())));
    await settle(tester);
  }

  /// Boots like [boot] but only lets the first frames and events run, so a wait is still visible.
  Future<void> bootEarly(WidgetTester tester, FakeServices fakes) async {
    services = fakes;
    await tester.runAsync(loadAppFonts);
    tester.view
      ..physicalSize = TestWindows.phone
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(HisaabApp(getIt: fakes.register(GetIt.asNewInstance())));
    for (int i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  FakeServices startedBy(LaunchAction action, {bool onboardingDone = true}) =>
      FakeServices(onboardingDone: onboardingDone)..shortcuts.launchedBy = Option<LaunchAction>.of(action);

  FakeServices withChaiHabit() => FakeServices(entries: chaiWeekdays(today: WorkedExample.today))
    ..categories.categories.add(chai)
    ..clock.current = DateTime(2026, 10, 26, 10, 5);

  group('Launches (widget spec §8)', () {
    testWidgets('Add on the widget, tile or shortcut that started the app opens the tray at the keypad', (WidgetTester tester) async {
      await boot(tester, startedBy(LaunchAction.add));

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('keypad-1')), findsOneWidget);
    });

    testWidgets('a cold-start Add waits for the habits, so your usual is in the first frame (D154)', (WidgetTester tester) async {
      final Completer<void> slow = Completer<void>();
      final FakeServices fakes = withChaiHabit()
        ..shortcuts.launchedBy = const Option<LaunchAction>.of(LaunchAction.add)
        ..states.nextReadGate = slow;
      await bootEarly(tester, fakes);
      expect(find.byType(AddEntryTray), findsNothing);

      slow.complete();
      await settle(tester);

      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(find.byKey(pillKey), findsOneWidget);
    });

    testWidgets('habits that never load let the tray open after a second, without the pill', (WidgetTester tester) async {
      final FakeServices fakes = withChaiHabit()
        ..shortcuts.launchedBy = const Option<LaunchAction>.of(LaunchAction.add)
        ..states.nextReadGate = Completer<void>();
      await bootEarly(tester, fakes);
      expect(find.byType(AddEntryTray), findsNothing);

      await tester.pump(const Duration(seconds: 1));
      await settle(tester);

      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(find.byKey(pillKey), findsNothing);
    });

    testWidgets('a running Add tap opens one tray; a second tap leaves it as it is', (WidgetTester tester) async {
      await boot(tester, FakeServices());

      services.shortcuts.tap(LaunchAction.add);
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey<String>('keypad-5')));
      await settle(tester);
      services.shortcuts.tap(LaunchAction.add);
      await settle(tester);

      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(find.text('₹5'), findsWidgets);
    });

    testWidgets('an Add tap while editing an entry keeps the edit tray (W6)', (WidgetTester tester) async {
      await boot(tester, FakeServices());
      await tester.tap(find.text('Groceries'));
      await settle(tester);
      final AddEntryBloc editing = tester.element(find.byType(AddEntryTray)).read<AddEntryBloc>();

      services.shortcuts.tap(LaunchAction.add);
      await settle(tester);

      expect(find.byType(AddEntryTray), findsOneWidget);
      expect(tester.element(find.byType(AddEntryTray)).read<AddEntryBloc>(), same(editing));
    });

    testWidgets('an Add tap in Settings goes back to Home, then opens the tray', (WidgetTester tester) async {
      await boot(tester, FakeServices());
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await settle(tester);

      services.shortcuts.tap(LaunchAction.add);
      await settle(tester);

      expect(find.byType(SettingsPage), findsNothing);
      expect(find.byType(AddEntryTray), findsOneWidget);
    });

    for (final LaunchAction action in <LaunchAction>[LaunchAction.home, LaunchAction.setUp]) {
      testWidgets('a ${action.name} tap in Settings goes back to Home and opens nothing', (WidgetTester tester) async {
        await boot(tester, FakeServices());
        await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
        await settle(tester);

        services.shortcuts.tap(action);
        await settle(tester);

        expect(find.byType(SettingsPage), findsNothing);
        expect(find.byType(HomePage), findsOneWidget);
        expect(find.byType(AddEntryTray), findsNothing);
      });
    }

    testWidgets('before onboarding is done, a tap lands on onboarding and is not kept for later (E51)', (WidgetTester tester) async {
      await boot(tester, startedBy(LaunchAction.add, onboardingDone: false));
      services.shortcuts.tap(LaunchAction.add);
      await settle(tester);

      expect(find.byType(OnboardingPage), findsOneWidget);
      expect(find.byType(AddEntryTray), findsNothing);
    });
  });

  group('Snapshot (widget spec §7)', () {
    testWidgets('is written when the app opens, with today first', (WidgetTester tester) async {
      await boot(tester, FakeServices());

      expect(services.shortcuts.published, isNotEmpty);
      expect(services.shortcuts.published.last.rows.first.hero, '₹1,430');
    });

    testWidgets('is written as set up before onboarding is done (E51)', (WidgetTester tester) async {
      await boot(tester, FakeServices(onboardingDone: false, entries: <Entry>[], rules: <RecurringRule>[]));

      expect(services.shortcuts.published.last.rows.first.state, WidgetDayState.setUp);
    });

    testWidgets('is written again after a save, on resume and when the look changes', (WidgetTester tester) async {
      await boot(tester, FakeServices());

      await services.ledger.add(EntryDraft(amount: Money.fromMajor(300), kind: EntryKind.spent, categoryId: 2, date: WorkedExample.today)).run();
      await settle(tester);
      expect(services.shortcuts.published.last.rows.first.hero, '₹1,130');

      final int before = services.shortcuts.published.length;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle(tester);
      expect(services.shortcuts.published.length, greaterThan(before));

      await services.preferences.saveThemeChoice(ThemeChoice.dark).run();
      tester.element(find.byType(HomePage)).read<ThemeBloc>().add(const ThemeLoadRequested());
      await settle(tester);
      expect(services.shortcuts.published.last.look, ThemeChoice.dark);
    });
  });
}
