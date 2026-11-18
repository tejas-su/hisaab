import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' show Option;
import 'package:get_it/get_it.dart';
import 'package:hisaab/app/hisaab_app.dart';
import 'package:hisaab/home/presentation/widgets/missed_log_row.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/fake_services.dart';
import '../helpers/fixtures/habits/chai_habit.dart';
import '../helpers/fixtures/ledger/categories.dart';
import '../helpers/fixtures/ledger/worked_example.dart';
import '../helpers/pump_app.dart';

const String _title = 'Remind you about this each day?';
const ValueKey<String> _yes = ValueKey<String>('nudge-yes');
const ValueKey<String> _no = ValueKey<String>('nudge-no');

final Entry _pay = entryAt(900, seedCategories.firstWhere((Category c) => c.id == SeedCategoryIds.salary), 45000, DateTime(2026, 10, 4, 9), kind: EntryKind.got);

Future<void> _settle(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>.delayed(Duration.zero));
  await tester.pumpAndSettle();
}

void main() {
  late FakeServices services;

  tearDown(() => services.dispose());

  Future<void> boot(WidgetTester tester, {Option<bool> choice = const Option<bool>.none(), bool granted = true}) async {
    services = FakeServices(entries: <Entry>[...chaiWeekdays(today: WorkedExample.today), _pay], rules: <RecurringRule>[WorkedExample.salary])
      ..categories.categories.add(chai)
      ..clock.current = DateTime(2026, 10, 26, 13)
      ..preferences.nudgesOn = choice
      ..nudges.granted = granted;
    await tester.runAsync(loadAppFonts);
    tester.view
      ..physicalSize = TestWindows.phone
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(HisaabApp(getIt: services.register(GetIt.asNewInstance())));
    await _settle(tester);
  }

  Future<void> tapLineAndCloseTray(WidgetTester tester) async {
    await tester.tap(find.byType(MissedLogRow));
    await _settle(tester);
    await tester.binding.handlePopRoute();
    await _settle(tester);
  }

  group('the nudge ask after the missed-log tap (BR-22.8, FR-SE-7 AC-4)', () {
    testWidgets('rises after the Add tray closes, not before, and not on a cold start', (WidgetTester tester) async {
      await boot(tester);
      expect(find.text(_title), findsNothing);

      await tester.tap(find.byType(MissedLogRow));
      await _settle(tester);
      expect(find.text(_title), findsNothing);

      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(find.text(_title), findsOneWidget);
      expect(find.text('Remind me'), findsOneWidget);
      expect(find.text('Not now'), findsOneWidget);
    });

    testWidgets('the tap still opens the tray with the line unchanged (entry speed): no extra step before it', (WidgetTester tester) async {
      await boot(tester);

      await tester.tap(find.byType(MissedLogRow));
      await _settle(tester);

      expect(find.byKey(const ValueKey<String>('add-next')), findsOneWidget);
      expect(services.preferences.nudgesOn, const Option<bool>.none());
    });

    testWidgets('Remind me with the permission stores on, asks Android once and re-arms', (WidgetTester tester) async {
      await boot(tester);
      final int armsBefore = services.nudges.arms;
      await tapLineAndCloseTray(tester);

      await tester.tap(find.byKey(_yes));
      await _settle(tester);

      expect(services.preferences.nudgesOn, const Option<bool>.of(true));
      expect(services.nudges.permissionAsks, 1);
      expect(services.nudges.arms, greaterThan(armsBefore));
      expect(find.text(_title), findsNothing);
    });

    testWidgets('Not now stores off, never asks Android, and is never asked again', (WidgetTester tester) async {
      await boot(tester);
      await tapLineAndCloseTray(tester);

      await tester.tap(find.byKey(_no));
      await _settle(tester);
      expect((services.preferences.nudgesOn, services.nudges.permissionAsks), (const Option<bool>.of(false), 0));
    });

    testWidgets('a refusal stores off, shows the line once, and is never asked again (E122)', (WidgetTester tester) async {
      await boot(tester, granted: false);
      await tapLineAndCloseTray(tester);

      await tester.tap(find.byKey(_yes));
      await _settle(tester);

      expect(services.preferences.nudgesOn, const Option<bool>.of(false));
      expect(find.text("Allow notifications in your phone's settings to turn this on."), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('nudge-refused-done')));
      await _settle(tester);
      expect(find.byType(NudgeRefusedSheet), findsNothing);
      expect(services.nudges.permissionAsks, 1);
    });

    for (final bool answered in <bool>[true, false]) {
      testWidgets('an earlier answer of ${answered ? 'yes' : 'no'} asks nothing after the tap', (WidgetTester tester) async {
        await boot(tester, choice: Option<bool>.of(answered));
        await tapLineAndCloseTray(tester);

        expect(find.text(_title), findsNothing);
        expect(services.preferences.nudgesOn, Option<bool>.of(answered));
      });
    }

    testWidgets('a pill add shows Undo with no ask over it; Undo works; the next tap on the line asks (FR-AD-10, D203)', (WidgetTester tester) async {
      await boot(tester);
      await tester.tap(find.byType(MissedLogRow));
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey<String>('usual-pill')));
      await _settle(tester);
      expect(find.text(_title), findsNothing);
      expect(services.preferences.nudgesOn, const Option<bool>.none());

      await tester.tap(find.text('Undo'));
      await _settle(tester);
      expect(services.ledger.saved, hasLength(1));
      expect(find.text(_title), findsNothing);
    });

    testWidgets('Back on the sheet gives no answer, so a later tap may ask again', (WidgetTester tester) async {
      await boot(tester);
      await tapLineAndCloseTray(tester);

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(find.text(_title), findsNothing);
      expect(services.preferences.nudgesOn, const Option<bool>.none());
    });
  });

  group('the Settings row, end to end (FR-SE-7)', () {
    Future<void> openSettings(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      await _settle(tester);
    }

    testWidgets('flipping it on asks Android and re-arms Home\'s reminders bloc', (WidgetTester tester) async {
      await boot(tester);
      await openSettings(tester);
      final int armsBefore = services.nudges.arms;

      await tester.ensureVisible(find.byKey(const ValueKey<String>('nudge-row')));
      await tester.tap(find.byKey(const ValueKey<String>('nudge-row')));
      await _settle(tester);

      expect(services.preferences.nudgesOn, const Option<bool>.of(true));
      expect(services.nudges.permissionAsks, 1);
      expect(services.nudges.arms, greaterThan(armsBefore));
    });
  });
}
