import 'dart:ui';

import 'package:expense_tracker/core/design/hisaab_dimensions.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/core/time/calendar_date.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/settings/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_app_preferences_repository.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_recurring_repository.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeAppPreferencesRepository preferences;
  late ThemeBloc themeBloc;
  late FakeRecurringRepository recurring;
  late IncomeBloc incomeBloc;

  setUp(() {
    preferences = FakeAppPreferencesRepository();
    themeBloc = ThemeBloc(preferences: preferences);
    recurring = FakeRecurringRepository(WorkedExample.rules);
    final FakeLedgerRepository ledger = FakeLedgerRepository(WorkedExample.entries);
    final FakeClock clock = FakeClock(WorkedExample.now);
    incomeBloc = IncomeBloc(getIncome: GetIncome(recurring: recurring, ledger: ledger, clock: clock), recurring: recurring, ledger: ledger);
  });
  tearDown(() async {
    await themeBloc.close();
    await incomeBloc.close();
  });

  SettingsPage page({VoidCallback? onOpenBills, VoidCallback? onOpenSavings, ValueChanged<Income>? onOpenIncome}) => SettingsPage(
        incomeBloc: incomeBloc,
        onOpenIncome: onOpenIncome ?? (Income _) {},
        onOpenBills: onOpenBills ?? () {},
        onOpenSavings: onOpenSavings ?? () {},
        themeBloc: themeBloc,
      );

  group('SettingsPage (FR-SE)', () {
    testWidgets('shows the Money group with Bills, which opens (D123)', (WidgetTester tester) async {
      int opened = 0;
      await pumpApp(tester, page(onOpenBills: () => opened++));
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Money'), findsOneWidget);
      await tester.tap(find.text('Bills'));
      expect(opened, 1);
    });

    testWidgets('lays out on a 320dp phone at 2× text', (WidgetTester tester) async {
      await pumpApp(tester, page(), size: TestWindows.smallPhone, textScale: 2);
      expect(tester.takeException(), isNull);
    });

    // why: a bare transparent bar is black at alpha 0, which Material reads as a dark bar, so it
    // asked for white status icons on the light page (D96).
    for (final (ThemeMode mode, Brightness icons) in <(ThemeMode, Brightness)>[
      (ThemeMode.light, Brightness.dark),
      (ThemeMode.dark, Brightness.light),
    ]) {
      testWidgets('status-bar icons contrast with the page in $mode', (WidgetTester tester) async {
        await pumpApp(tester, page(), themeMode: mode);
        final AnnotatedRegion<SystemUiOverlayStyle> bar = tester.widget(
          find.descendant(of: find.byType(AppBar), matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>)),
        );
        expect(bar.value.statusBarIconBrightness, icons);
      });
    }

    testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, page());
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  group('SettingsPage savings (D120)', () {
    testWidgets('Savings opens the savings list', (WidgetTester tester) async {
      int opened = 0;
      await pumpApp(tester, page(onOpenSavings: () => opened++));
      expect(find.descendant(of: find.byKey(const ValueKey<String>('open-savings')), matching: find.text('Savings')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey<String>('open-savings')));
      expect(opened, 1);
    });
  });

  group('SettingsPage look (FR-SE-3)', () {
    Finder choice(String key) => find.byKey(ValueKey<String>('look-$key'));
    final Finder tile = find.byKey(const ValueKey<String>('look-tile'));

    bool picked(WidgetTester tester, String key) =>
        tester.getSemantics(choice(key)).flagsCollection.isSelected == Tristate.isTrue;

    testWidgets('one Light or dark row under Look names the current look, Match phone picked', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, page());
      expect(find.text('Look'), findsOneWidget);
      expect(tester.getTopLeft(find.text('Look')).dy, greaterThan(tester.getTopLeft(find.text('Savings')).dy));
      expect(find.descendant(of: tile, matching: find.text('Light or dark')), findsOneWidget);
      expect(find.descendant(of: tile, matching: find.text('Match phone')), findsOneWidget);
      expect(picked(tester, 'matchPhone'), isTrue);
      expect(picked(tester, 'light'), isFalse);
      expect(picked(tester, 'dark'), isFalse);
      handle.dispose();
    });

    testWidgets('one tap on an icon picks the look, saves it and names it', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, page());
      await tester.tap(choice('dark'));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      expect(themeBloc.state.choice, ThemeChoice.dark);
      expect(preferences.theme, ThemeChoice.dark);
      expect(picked(tester, 'dark'), isTrue);
      expect(picked(tester, 'matchPhone'), isFalse);
      expect(find.descendant(of: tile, matching: find.text('Dark')), findsOneWidget);
      handle.dispose();
    });

    testWidgets('each icon is labelled, in one group of exclusive choices', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, page());
      for (final (String key, String label) in <(String, String)>[('matchPhone', 'like your phone'), ('light', 'Light'), ('dark', 'Dark')]) {
        expect(tester.getSemantics(choice(key)).flagsCollection.isInMutuallyExclusiveGroup, isTrue);
        expect(tester.getSemantics(choice(key)).label, contains(label));
      }
      handle.dispose();
    });

    testWidgets('the icons sit in one row at the tile\'s end edge, 48dp each', (WidgetTester tester) async {
      await pumpApp(tester, page());
      expect(tester.getCenter(choice('light')).dy, tester.getCenter(choice('matchPhone')).dy);
      expect(tester.getCenter(choice('dark')).dy, tester.getCenter(choice('matchPhone')).dy);
      expect(tester.getSize(choice('dark')), const Size.square(HisaabSizes.minTouchTarget));
      final Rect savings = tester.getRect(find.byKey(const ValueKey<String>('open-savings')));
      expect(tester.getRect(find.byKey(const ValueKey<String>('look-track'))).right, savings.right - HisaabSpacing.gutter);
      expect(tester.getRect(find.text('Light or dark')).left, savings.left + HisaabSpacing.gutter);
    });

    testWidgets('at 2× text on a 320dp phone the icons move under the words, so no word breaks', (WidgetTester tester) async {
      await pumpApp(tester, page(), size: TestWindows.smallPhone, textScale: 2);
      expect(tester.takeException(), isNull);
      final Finder value = find.descendant(of: tile, matching: find.text('Match phone'));
      expect(tester.getRect(find.byKey(const ValueKey<String>('look-track'))).top, greaterThanOrEqualTo(tester.getRect(value).bottom));
      expect(tester.getRect(find.byKey(const ValueKey<String>('look-track'))).left, tester.getRect(find.text('Light or dark')).left);
      expect(tester.getCenter(choice('dark')).dy, tester.getCenter(choice('matchPhone')).dy);
    });

    for (final (Size size, double scale) in <(Size, double)>[
      (const Size(360, 800), 1),
      (const Size(360, 800), 1.3),
      (TestWindows.phoneLandscape, 1),
      (TestWindows.foldableUnfolded, 1),
      (TestWindows.tablet, 1),
    ]) {
      testWidgets('keeps the icons beside the words at $size, $scale× text', (WidgetTester tester) async {
        await pumpApp(tester, page(), size: size, textScale: scale);
        expect(tester.takeException(), isNull);
        expect(tester.getCenter(choice('dark')).dy, tester.getCenter(choice('matchPhone')).dy);
        expect(tester.getRect(find.byKey(const ValueKey<String>('look-track'))).left,
            greaterThan(tester.getRect(find.text('Light or dark')).right));
      });
    }

    testWidgets('meets the guidelines in dark', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpApp(tester, page(), themeMode: ThemeMode.dark);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });

  group('SettingsPage money coming in (FR-SE-1, D137)', () {
    final Finder row = find.byKey(const ValueKey<String>('open-income'));

    testWidgets('is the first Money row and shows the income once loaded', (WidgetTester tester) async {
      await tester.runAsync(() => incomeBloc.dispatch(const IncomeLoadRequested()));
      await pumpApp(tester, page());
      expect(find.descendant(of: row, matching: find.text('Money coming in')), findsOneWidget);
      expect(find.descendant(of: row, matching: find.text('₹45,000 · on day 4')), findsOneWidget);
      expect(tester.getTopLeft(row).dy, lessThan(tester.getTopLeft(find.byKey(const ValueKey<String>('open-bills'))).dy));
    });

    testWidgets('opens the income sheet with the loaded income', (WidgetTester tester) async {
      await tester.runAsync(() => incomeBloc.dispatch(const IncomeLoadRequested()));
      Income? opened;
      await pumpApp(tester, page(onOpenIncome: (Income income) => opened = income));
      await tester.tap(row);
      expect(opened?.rule.toNullable(), WorkedExample.salary);
    });

    testWidgets('shows the label only and doesn\'t open while loading', (WidgetTester tester) async {
      Income? opened;
      await pumpApp(tester, page(onOpenIncome: (Income income) => opened = income));
      expect(find.descendant(of: row, matching: find.text('Money coming in')), findsOneWidget);
      expect(find.textContaining('₹45,000'), findsNothing);
      await tester.tap(row);
      expect(opened, isNull);
    });

    for (final (String name, RecurringRule? rule, String value) in <(String, RecurringRule?, String)>[
      (
        'last day',
        WorkedExample.salary.copyWith(
          schedule: const Schedule(frequency: Frequency.monthly, anchor: CalendarDate(2026, 10, 31), lastDayOfMonth: true),
        ),
        '₹45,000 · last day of the month',
      ),
      (
        'weekly',
        WorkedExample.salary.copyWith(
          amount: Money.fromMajor(10384),
          schedule: const Schedule(frequency: Frequency.weekly, anchor: CalendarDate(2026, 10, 23)),
        ),
        '₹44,998 · every Friday',
      ),
      ('it changes', null, 'Changes each month'),
      (
        'biweekly',
        WorkedExample.salary.copyWith(schedule: const Schedule(frequency: Frequency.biweekly, anchor: CalendarDate(2026, 10, 16))),
        'Changes each month',
      ),
    ]) {
      testWidgets('names a $name income', (WidgetTester tester) async {
        recurring.rules = <RecurringRule>[?rule, WorkedExample.rent];
        await tester.runAsync(() => incomeBloc.dispatch(const IncomeLoadRequested()));
        await pumpApp(tester, page());
        expect(find.descendant(of: row, matching: find.text(value)), findsOneWidget);
      });
    }

    testWidgets('lays out with the income on a 320dp phone at 2× text', (WidgetTester tester) async {
      await tester.runAsync(() => incomeBloc.dispatch(const IncomeLoadRequested()));
      await pumpApp(tester, page(), size: TestWindows.smallPhone, textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });
}
