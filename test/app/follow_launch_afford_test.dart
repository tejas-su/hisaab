import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hisaab/add_entry/add_entry.dart';
import 'package:hisaab/app/hisaab_app.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/onboarding/onboarding.dart';
import 'package:hisaab/shortcuts/shortcuts.dart';
import 'package:hisaab/spends/spends.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_services.dart';
import '../helpers/fixtures/ledger/categories.dart';
import '../helpers/pump_app.dart';

/// The *Can I afford it?* app shortcut through the whole app (SPEC FR-WG-9).
void main() {
  late FakeServices services;

  tearDown(() => services.dispose());

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
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

  testWidgets('with income, the tap shows Spends with the check up', (WidgetTester tester) async {
    await boot(tester, FakeServices());
    services.shortcuts.tap(LaunchAction.afford);
    await settle(tester);

    expect(find.byType(SpendsPage), findsOneWidget);
    expect(find.byType(AffordSheet), findsOneWidget);
  });

  testWidgets('with the Add tray open, it closes the tray and shows the check', (WidgetTester tester) async {
    await boot(tester, FakeServices());
    services.shortcuts.tap(LaunchAction.add);
    await settle(tester);
    expect(find.byType(AddEntryTray), findsOneWidget);
    services.shortcuts.tap(LaunchAction.afford);
    await settle(tester);

    expect(find.byType(AddEntryTray), findsNothing);
    expect(find.byType(AffordSheet), findsOneWidget);
  });

  testWidgets('from Settings it goes back first, then shows the check', (WidgetTester tester) async {
    await boot(tester, FakeServices());
    await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
    await settle(tester);
    services.shortcuts.tap(LaunchAction.afford);
    await settle(tester);

    expect(find.byType(SpendsPage), findsOneWidget);
    expect(find.byType(AffordSheet), findsOneWidget);
  });

  testWidgets('with no income, it shows Spends and no sheet', (WidgetTester tester) async {
    await boot(tester, FakeServices(entries: <Entry>[], rules: <RecurringRule>[]));
    services.shortcuts.tap(LaunchAction.afford);
    await settle(tester);

    expect(find.byType(SpendsPage), findsOneWidget);
    expect(find.byType(AffordSheet), findsNothing);
  });

  testWidgets('It changes with pay last month and none this month: the tap shows the check (D223)', (WidgetTester tester) async {
    await boot(
      tester,
      FakeServices(
        rules: <RecurringRule>[],
        entries: <Entry>[
          Entry(id: 1, amount: Money.fromMajor(30000), kind: EntryKind.got, categoryId: SeedCategoryIds.otherIncome, date: const CalendarDate(2026, 9, 20), createdAt: DateTime(2026, 9, 20)),
        ],
      ),
    );
    services.shortcuts.tap(LaunchAction.afford);
    await settle(tester);

    expect(find.byType(SpendsPage), findsOneWidget);
    expect(find.byType(AffordSheet), findsOneWidget);
  });

  testWidgets('with the check open at step 2, it keeps that sheet and its draft (E167)', (WidgetTester tester) async {
    await boot(tester, FakeServices());
    services.shortcuts.tap(LaunchAction.afford);
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey<String>('afford-name')), 'Mac');
    for (final String key in '127000'.split('')) {
      await tester.tap(find.byKey(ValueKey<String>('keypad-$key')));
      await settle(tester);
    }
    await tester.tap(find.byKey(const ValueKey<String>('afford-next')));
    await settle(tester);
    expect(find.text('Saved anything for it already?'), findsOneWidget);

    services.shortcuts.tap(LaunchAction.afford);
    await settle(tester);

    expect(find.byType(AffordSheet), findsOneWidget);
    expect(find.text('Saved anything for it already?'), findsOneWidget);
    expect(find.textContaining('₹1,27,000'), findsWidgets);
  });

  testWidgets('during onboarding it is ignored', (WidgetTester tester) async {
    await boot(tester, FakeServices(onboardingDone: false));
    services.shortcuts.tap(LaunchAction.afford);
    await settle(tester);

    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.byType(AffordSheet), findsNothing);
  });
}
