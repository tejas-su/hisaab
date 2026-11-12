import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/widgets/hisaab_snackbar_bar.dart';
import 'package:hisaab/core/widgets/hisaab_snackbar_host.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_suggestion_state_repository.dart';
import '../../../helpers/fixtures/habits/chai_habit.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeLedgerRepository ledger;
  late FakeSuggestionStateRepository states;
  late HabitsBloc bloc;

  /// The entry a pill tap saved, as the ledger holds it.
  final Entry tapped = entryAt(900, chai, 20, DateTime(2026, 10, 26, 10, 5));

  setUp(() {
    ledger = FakeLedgerRepository(<Entry>[tapped]);
    states = FakeSuggestionStateRepository();
    final FakeClock clock = FakeClock(DateTime(2026, 10, 26, 10, 5));
    final FakeCategoryRepository categories = FakeCategoryRepository(<Category>[...seedCategories, chai]);
    bloc = HabitsBloc(
      getIndex: GetHabitIndex(ledger: ledger, categories: categories, states: states, clock: clock),
      undoAdd: UndoUsualAdd(states: states, ledger: ledger, clock: clock),
      ledger: ledger,
    );
  });

  tearDown(() async {
    await bloc.close();
    await ledger.dispose();
  });

  Future<void> send(WidgetTester tester, HabitsEvent event) async {
    bloc.add(event);
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
  }

  /// Pumps a page under the notice with today's habits loaded, then reports a pill add.
  Future<void> pumpAdded(
    WidgetTester tester, {
    Category category = chai,
    Entry? entry,
    Size size = TestWindows.phone,
    double textScale = 1,
    bool talkBack = false,
  }) async {
    if (talkBack) {
      tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(accessibleNavigation: true);
      addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    }
    await pumpApp(
      tester,
      Scaffold(
        body: BlocProvider<HabitsBloc>.value(
          value: bloc,
          child: UsualAddedNotice(
            child: KeyedSubtree(key: ValueKey<int>(category.id), child: const SizedBox.expand(key: ValueKey<String>('page'))),
          ),
        ),
      ),
      size: size,
      textScale: textScale,
    );
    await send(tester, const HabitsLoadRequested());
    await send(tester, HabitsUsualAdded(UsualAdd(entry: entry ?? tapped, category: category)));
    await tester.pumpAndSettle();
  }

  group('UsualAddedNotice (BR-10)', () {
    testWidgets('shows nothing until a usual is added', (WidgetTester tester) async {
      await pumpApp(
        tester,
        Scaffold(body: BlocProvider<HabitsBloc>.value(value: bloc, child: const UsualAddedNotice(child: SizedBox.expand()))),
      );
      await send(tester, const HabitsLoadRequested());
      await tester.pumpAndSettle();
      expect(find.byType(HisaabSnackbarBar), findsNothing);
    });

    testWidgets('shows Added ₹20 to Chai with Undo when a usual is added', (WidgetTester tester) async {
      await pumpAdded(tester);
      expect(find.text('Added ₹20 to Chai'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
    });

    testWidgets('sits at the bottom edge of the page it wraps, inside the gutters', (WidgetTester tester) async {
      await pumpAdded(tester);
      final Rect page = tester.getRect(find.byKey(const ValueKey<String>('page')));
      final Rect bar = tester.getRect(find.byType(HisaabSnackbarBar));
      expect(bar.bottom, page.bottom);
      expect((bar.left, bar.right), (page.left + 20, page.right - 20));
    });

    testWidgets('TalkBack hears Added 20 rupees to Chai', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpAdded(tester);
      expect(find.bySemanticsLabel('Added 20 rupees to Chai'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Undo sends HabitsUsualUndoRequested once: the entry goes and its category is quiet', (WidgetTester tester) async {
      await pumpAdded(tester);
      await tester.tap(find.text('Undo'));
      await tester.pump();
      await tester.tap(find.text('Undo'), warnIfMissed: false);
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      expect(ledger.entries, isEmpty);
      expect(states.calls.where((String call) => call == 'put:${chai.id}'), hasLength(1));
      expect(find.byType(HisaabSnackbarBar), findsNothing);
    });

    testWidgets('it leaves after 4 s', (WidgetTester tester) async {
      await pumpAdded(tester);
      await tester.pump(HisaabSnackbarHost.visibleFor);
      await tester.pumpAndSettle();
      expect(find.text('Added ₹20 to Chai'), findsNothing);
      expect(ledger.entries, <Entry>[tapped]);
    });

    testWidgets('with TalkBack it stays until dismissed (D105)', (WidgetTester tester) async {
      await pumpAdded(tester, talkBack: true);
      await tester.pump(HisaabSnackbarHost.visibleFor * 3);
      await tester.pumpAndSettle();
      expect(find.text('Added ₹20 to Chai'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.runAsync(pumpEventQueue);
      await tester.pumpAndSettle();
      expect(find.text('Added ₹20 to Chai'), findsNothing);
    });

    testWidgets('a reload does not show it twice', (WidgetTester tester) async {
      await pumpAdded(tester);
      await tester.pump(HisaabSnackbarHost.visibleFor);
      await tester.pumpAndSettle();
      await send(tester, const HabitsLoadRequested());
      await tester.pumpAndSettle();
      expect(find.byType(HisaabSnackbarBar), findsNothing);
    });

    testWidgets("a renamed category's name is used (BR-11)", (WidgetTester tester) async {
      await pumpAdded(tester, category: chai.copyWith(customName: 'Cutting'));
      expect(find.text('Added ₹20 to Cutting'), findsOneWidget);
    });

    testWidgets("a built-in category's localised name is used (BR-11)", (WidgetTester tester) async {
      await pumpAdded(tester, category: food, entry: entryAt(901, food, 120, DateTime(2026, 10, 26, 13)));
      expect(find.text('Added ₹120 to Food'), findsOneWidget);
    });

    testWidgets('fits a 320dp phone at 2× text (NFR-4)', (WidgetTester tester) async {
      await pumpAdded(
        tester,
        size: TestWindows.smallPhone,
        textScale: 2,
        category: chai.copyWith(customName: 'Wwwwwwwwwwwwwwww'),
        entry: entryAt(902, chai, 999999999, DateTime(2026, 10, 26, 10, 5)),
      );
      expect(find.text('Added ₹99,99,99,999 to Wwwwwwwwwwwwwwww'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('meets tap-target, label and contrast guidelines', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpAdded(tester);
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });
  });
}
