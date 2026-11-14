import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:hisaab/app/hisaab_app.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/time/calendar_date.dart';
import 'package:hisaab/fix/fix.dart';
import 'package:hisaab/home/presentation/widgets/install_line_row.dart';
import 'package:hisaab/ledger/ledger.dart';

import '../helpers/fake_services.dart';
import '../helpers/fixtures/ledger/worked_example.dart';
import '../helpers/pump_app.dart';

/// Mon 26 Oct 2026, cycle 4 Oct to 3 Nov. Onboarding on the 26th posts the salary back to the 4th, so
/// the earliest entry was saved today: a mid-cycle install (FR-HO-3, C1).
final Entry _payPostedAtInstall = Entry(
  id: 1,
  amount: Money.fromMajor(45000),
  kind: EntryKind.got,
  categoryId: 9,
  date: const CalendarDate(2026, 10, 4),
  createdAt: DateTime(2026, 10, 26, 9),
  recurringId: 1,
);

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  late FakeServices services;

  tearDown(() => services.dispose());

  Future<void> boot(WidgetTester tester, FakeServices fakes) async {
    services = fakes;
    await tester.runAsync(loadAppFonts);
    tester.view
      ..physicalSize = TestWindows.phone
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(HisaabApp(getIt: fakes.register(GetIt.asNewInstance())));
    await _settle(tester);
  }

  FakeServices installed({List<RecurringRule>? rules, bool seen = false}) =>
      FakeServices(entries: <Entry>[_payPostedAtInstall], rules: rules ?? <RecurringRule>[WorkedExample.salary])..settings.installSeen = seen;

  Future<void> resume(WidgetTester tester) async {
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await _settle(tester);
  }

  group('the install line, end to end (FR-HO-3, FR-FX-1)', () {
    testWidgets('a mid-cycle install shows it on its first Home visit, and marks it seen once it is on screen', (WidgetTester tester) async {
      await boot(tester, installed());

      expect(find.byType(InstallLineRow), findsOneWidget);
      expect(find.text('Already spent some this month?'), findsOneWidget);
      expect(find.text('Fix my number'), findsWidgets);
      expect(services.settings.installSeen, isTrue);
    });

    testWidgets('TalkBack reads it as one node: the question, the door and the hint', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await boot(tester, installed());

      final SemanticsData data = tester.getSemantics(find.byType(InstallLineRow)).getSemanticsData();
      expect(data.label, 'Already spent some this month? Fix my number');
      expect(data.hint, 'Opens the keypad.');
      handle.dispose();
    });

    testWidgets('it never returns after it was seen, on the next resume or a later visit', (WidgetTester tester) async {
      await boot(tester, installed());
      expect(find.byType(InstallLineRow), findsOneWidget);

      await resume(tester);

      expect(find.byType(InstallLineRow), findsNothing);
    });

    testWidgets('not shown when the flag is already set (a restored backup), or the install day is the first day of the cycle', (WidgetTester tester) async {
      await boot(tester, installed(seen: true));
      expect(find.byType(InstallLineRow), findsNothing);
    });

    testWidgets('not shown on a plain install at the cycle start', (WidgetTester tester) async {
      await boot(tester, FakeServices(rules: <RecurringRule>[WorkedExample.salary]));

      expect(find.byType(InstallLineRow), findsNothing);
    });

    testWidgets('a bill line holds the slot, so the install line waits and is not marked seen', (WidgetTester tester) async {
      await boot(tester, installed(rules: WorkedExample.rules));

      expect(find.byType(InstallLineRow), findsNothing);
      expect(services.settings.installSeen, isFalse);
    });

    testWidgets('a tap opens the sheet; a fix closes it, the line goes and focus lands on the Today heading', (WidgetTester tester) async {
      await boot(tester, installed());

      await tester.tap(find.byType(InstallLineRow));
      await _settle(tester);
      expect(find.byType(FixSheet), findsOneWidget);
      for (final String digit in '40000'.split('')) {
        await tester.tap(find.byKey(ValueKey<String>('keypad-$digit')));
        await _settle(tester);
      }
      await tester.tap(find.byKey(const ValueKey<String>('fix-action')));
      await _settle(tester);

      expect(find.byType(FixSheet), findsNothing);
      expect(find.byType(InstallLineRow), findsNothing);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'Today heading');
      expect(services.ledger.entries.where((Entry e) => e.isNotLogged), hasLength(1));
      expect(services.settings.installSeen, isTrue);
    });

    testWidgets('a tap opens the sheet through the hold: Home keeps its number until the sheet has gone', (WidgetTester tester) async {
      await boot(tester, installed());

      await tester.tap(find.byType(InstallLineRow));
      await _settle(tester);
      await services.ledger
          .add(EntryDraft(amount: Money.fromMajor(100), kind: EntryKind.spent, categoryId: 1, date: WorkedExample.today))
          .run();
      await _settle(tester);
      expect(find.textContaining('₹100'), findsNothing);

      Navigator.of(tester.element(find.byType(FixSheet))).pop();
      await _settle(tester);

      expect(find.textContaining('₹100'), findsWidgets);
    });
  });
}
