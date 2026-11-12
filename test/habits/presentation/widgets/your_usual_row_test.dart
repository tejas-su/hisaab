import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hisaab/core/design/hisaab_colors.dart';
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
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

const ValueKey<String> _rowKey = ValueKey<String>('your-usual-row');
const ValueKey<String> _forgetKey = ValueKey<String>('usual-forget');

void main() {
  late FakeLedgerRepository ledger;
  late FakeSuggestionStateRepository states;
  late UsualRowBloc bloc;

  setUp(() {
    ledger = FakeLedgerRepository(chaiWeekdays(today: WorkedExample.today));
    states = FakeSuggestionStateRepository();
    final FakeClock clock = FakeClock(DateTime(2026, 10, 26, 10, 5));
    final FakeCategoryRepository categories = FakeCategoryRepository(<Category>[...seedCategories, chai]);
    bloc = UsualRowBloc(
      categoryId: chai.id,
      getIndex: GetHabitIndex(ledger: ledger, categories: categories, states: states, clock: clock),
      forget: ForgetUsual(states: states, clock: clock),
      restore: RestoreUsual(states: states),
      clock: clock,
    );
  });

  tearDown(() async {
    await bloc.close();
    await ledger.dispose();
  });

  Future<void> send(WidgetTester tester, UsualRowEvent event) async {
    bloc.add(event);
    await tester.runAsync(pumpEventQueue);
    await tester.pump();
  }

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.runAsync(pumpEventQueue);
    await tester.pumpAndSettle();
  }

  /// Pumps the row in a sheet-like column under a snackbar host, with the habit loaded.
  Future<void> pumpRow(
    WidgetTester tester, {
    String name = 'Chai',
    Size size = TestWindows.phone,
    double textScale = 1,
    ThemeMode themeMode = ThemeMode.light,
    bool load = true,
  }) async {
    await pumpApp(
      tester,
      Scaffold(
        body: HisaabSnackbarHost(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                BlocProvider<UsualRowBloc>.value(value: bloc, child: YourUsualRow(name: name)),
                const SizedBox(key: ValueKey<String>('below'), height: 300),
              ],
            ),
          ),
        ),
      ),
      size: size,
      textScale: textScale,
      themeMode: themeMode,
    );
    if (load) {
      await send(tester, const UsualRowLoadRequested());
      await tester.pumpAndSettle();
    }
  }

  group('YourUsualRow (FR-SE-2 AC-6)', () {
    testWidgets('shows Your usual, the detail, Forget and the note', (WidgetTester tester) async {
      await pumpRow(tester);
      expect(find.text('Your usual'), findsOneWidget);
      expect(find.text('₹20, weekdays around 10 am'), findsOneWidget);
      expect(find.text('Forget'), findsOneWidget);
      expect(find.text('Worked out on this phone from what you add.'), findsOneWidget);
    });

    testWidgets('the row is a surface card at least 56dp tall, with the note under it', (WidgetTester tester) async {
      await pumpRow(tester);
      final Rect row = tester.getRect(find.byKey(_rowKey));
      expect(row.height, greaterThanOrEqualTo(56));
      expect(tester.widget<Material>(find.byKey(_rowKey)).color, HisaabColors.light.surface);
      expect(tester.getTopLeft(find.text('Worked out on this phone from what you add.')).dy, greaterThan(row.bottom));
    });

    testWidgets('nothing is built without a habit', (WidgetTester tester) async {
      await pumpRow(tester, load: false);
      expect(find.byKey(_rowKey), findsNothing);
      expect(find.text('Worked out on this phone from what you add.'), findsNothing);
      expect(tester.getTopLeft(find.byKey(const ValueKey<String>('below'))).dy, 20);
    });

    testWidgets('TalkBack hears the amount in words and Forget your usual Chai', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpRow(tester);
      expect(find.bySemanticsLabel('Your usual\n20 rupees, weekdays around 10 am'), findsOneWidget);
      expect(tester.getSemantics(find.bySemanticsLabel('Forget your usual Chai')), isSemantics(isButton: true, hasTapAction: true));
      handle.dispose();
    });

    testWidgets('Forget reads the name it is given', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await pumpRow(tester, name: 'Cutting');
      expect(find.bySemanticsLabel('Forget your usual Cutting'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('Forget has a 48dp target', (WidgetTester tester) async {
      await pumpRow(tester);
      final Size target = tester.getSize(find.byKey(_forgetKey));
      expect(target.height, greaterThanOrEqualTo(48));
      expect(target.width, greaterThanOrEqualTo(48));
    });

    testWidgets('Forget removes the row and offers Forgotten with Undo in the host above', (WidgetTester tester) async {
      await pumpRow(tester);
      await tap(tester, find.byKey(_forgetKey));

      expect(find.byKey(_rowKey), findsNothing);
      expect(find.text('Forgotten'), findsOneWidget);
      expect(find.text('Undo'), findsOneWidget);
      expect(states.states[chai.id]?.forgottenAt.isSome(), isTrue);
    });

    testWidgets('Undo brings the row back and clears what Forget stored (E68)', (WidgetTester tester) async {
      await pumpRow(tester);
      await tap(tester, find.byKey(_forgetKey));
      await tap(tester, find.text('Undo'));

      expect(find.byKey(_rowKey), findsOneWidget);
      expect(find.byType(HisaabSnackbarBar), findsNothing);
      expect(states.states, isEmpty);
    });

    testWidgets('a reload does not show Forgotten twice', (WidgetTester tester) async {
      await pumpRow(tester);
      await tap(tester, find.byKey(_forgetKey));
      await tester.pump(HisaabSnackbarHost.visibleFor);
      await tester.pumpAndSettle();
      expect(find.byType(HisaabSnackbarBar), findsNothing);

      await send(tester, const UsualRowLoadRequested());
      await tester.pumpAndSettle();

      expect(find.byType(HisaabSnackbarBar), findsNothing);
      expect(find.byKey(_rowKey), findsNothing);
    });

    testWidgets('fits 320dp at 2× text with the longest name and the cap amount', (WidgetTester tester) async {
      ledger.entries
        ..removeWhere((Entry entry) => entry.categoryId == chai.id)
        ..addAll(entriesOn(daysBefore(WorkedExample.today, DayType.weekday), chai, rupees: 999999999, firstId: 501));
      await pumpRow(tester, name: 'Wwwwwwwwwwwwwwww', size: TestWindows.smallPhone, textScale: 2);
      expect(find.text('₹99,99,99,999, weekdays around 10 am'), findsOneWidget);
      expect(find.text('Forget'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    for (final ThemeMode mode in <ThemeMode>[ThemeMode.light, ThemeMode.dark]) {
      testWidgets('meets tap-target, label and contrast guidelines in ${mode.name}', (WidgetTester tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pumpRow(tester, themeMode: mode);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }
  });
}
