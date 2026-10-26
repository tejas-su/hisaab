import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/core/money/money.dart';
import 'package:expense_tracker/home/home.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeServices services;
  late HomeCubit cubit;
  late List<Object> calls;

  setUp(() {
    services = FakeServices();
    cubit = services.homeCubit();
    calls = <Object>[];
  });

  tearDown(() async {
    await cubit.close();
    await services.dispose();
  });

  Future<void> pump(WidgetTester tester, {bool load = true, Size size = TestWindows.phone, double textScale = 1, ThemeMode theme = ThemeMode.light}) async {
    if (load) {
      await tester.runAsync(cubit.load);
    }
    await pumpApp(
      tester,
      BlocProvider<HomeCubit>.value(
        value: cubit,
        child: Scaffold(
          body: HomePage(
            onAdd: (EntryKind kind) => calls.add(kind),
            onEdit: (Entry entry) => calls.add(entry),
            onOpenSettings: () => calls.add('settings'),
          ),
        ),
      ),
      size: size,
      textScale: textScale,
      themeMode: theme,
    );
  }

  group('HomePage (FR-HO)', () {
    testWidgets('loading shows the hero card without a number', (WidgetTester tester) async {
      await pump(tester, load: false);
      expect(find.text('Safe to spend today'), findsOneWidget);
      expect(find.textContaining('₹'), findsNothing);
    });

    testWidgets('shows the worked example: date, ₹1,430, payday flag, range line and today\'s rows', (WidgetTester tester) async {
      await pump(tester);
      expect(find.text('Mon, 26 Oct'), findsOneWidget);
      expect(find.text('₹1,430'), findsOneWidget);
      expect(find.text('4 Nov'), findsOneWidget);
      expect(find.text('9 days to payday'), findsOneWidget);
      expect(find.textContaining('Lasts till payday'), findsOneWidget);
      expect(find.text('Chai & samosa'), findsOneWidget);
      expect(find.text('₹420'), findsOneWidget);
    });

    testWidgets('TalkBack reads the hero as one sentence (FR-HO-7)', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      expect(
        find.bySemanticsLabel(RegExp('^Safe to spend today: 1,430 rupees. 9 days to payday. Lasts till payday, about 9,300 rupees spare.')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('Settings opens from the header', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const ValueKey<String>('open-settings')));
      expect(calls, <Object>['settings']);
    });

    testWidgets('tapping a row edits it (FR-AD-8)', (WidgetTester tester) async {
      await pump(tester);
      await tester.tap(find.text('Chai & samosa'));
      expect(calls.single, WorkedExample.entries[3]);
    });

    testWidgets('swiping deletes at once and Undo brings it back (BR-10)', (WidgetTester tester) async {
      await pump(tester);
      await tester.drag(find.text('Chai & samosa'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('Chai & samosa'), findsNothing);
      expect(find.text('Deleted ₹60'), findsOneWidget);
      expect(services.haptics.events, contains('threshold'));
      await tester.tap(find.text('Undo'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.text('Chai & samosa'), findsOneWidget);
    });

    testWidgets('TalkBack users can delete a row without swiping', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      final SemanticsNode row = tester.getSemantics(find.text('Chai & samosa'));
      expect(row.getSemanticsData().customSemanticsActionIds, isNotEmpty);
      handle.dispose();
    });

    testWidgets('an empty day says what to do', (WidgetTester tester) async {
      services.ledger.entries.removeWhere((Entry e) => e.date == WorkedExample.today);
      await pump(tester);
      expect(find.text('Nothing spent today. Tap Add when you do.'), findsOneWidget);
    });

    testWidgets('a Got entry shows with a plus', (WidgetTester tester) async {
      await services.ledger
          .add(EntryDraft(amount: Money.fromMajor(500), kind: EntryKind.got, categoryId: 10, date: WorkedExample.today))
          .run();
      await pump(tester);
      expect(find.text('+₹500'), findsOneWidget);
    });

    testWidgets('no income asks for money in and opens Add on Got (E10)', (WidgetTester tester) async {
      services.recurring.rules = <RecurringRule>[];
      services.ledger.entries.removeWhere((Entry e) => e.kind == EntryKind.got);
      await pump(tester);
      expect(find.text('Add money you got this month'), findsOneWidget);
      await tester.tap(find.text('Add money'));
      expect(calls, <Object>[EntryKind.got]);
    });

    testWidgets('a failed load says so and Try again reloads', (WidgetTester tester) async {
      services.ledger.failure = DatabaseFailure('locked');
      await pump(tester);
      expect(find.text("Couldn't load your money."), findsOneWidget);
      services.ledger.failure = null;
      await tester.tap(find.text('Try again'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pumpAndSettle();
      expect(find.text('₹1,430'), findsOneWidget);
    });

    testWidgets('over today, in dark mode: ₹0 with the overspend in words (BR-5)', (WidgetTester tester) async {
      await services.ledger
          .add(EntryDraft(amount: Money.fromMajor(2450), kind: EntryKind.spent, categoryId: 3, date: WorkedExample.today))
          .run();
      await pump(tester, theme: ThemeMode.dark);
      expect(find.text('₹0'), findsOneWidget);
      expect(find.text('₹1,020 over today'), findsOneWidget);
      expect(find.text('Each day after: ₹1,722'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    final List<(String, Size, double)> windows = <(String, Size, double)>[
      ('a 320dp phone at 2× text', TestWindows.smallPhone, 2),
      ('a phone at 1.5× text (E12)', TestWindows.phone, 1.5),
      ('a split-screen window (E18)', const Size(412, 400), 1),
      ('a phone in landscape', TestWindows.phoneLandscape, 1),
    ];
    for (final (String name, Size size, double scale) in windows) {
      testWidgets('lays out without overflow on $name', (WidgetTester tester) async {
        await pump(tester, size: size, textScale: scale);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pump(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
