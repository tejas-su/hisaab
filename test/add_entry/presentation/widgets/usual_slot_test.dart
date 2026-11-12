import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hisaab/add_entry/add_entry.dart';
import 'package:hisaab/add_entry/presentation/widgets/spend_preview_line.dart';
import 'package:hisaab/add_entry/presentation/widgets/usual_pill.dart';
import 'package:hisaab/add_entry/presentation/widgets/usual_slot.dart';
import 'package:hisaab/core/design/hisaab_motion.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/habits/chai_habit.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeServices services;
  late AddEntryBloc bloc;

  final Option<UsualSpend> chaiTwenty = Option<UsualSpend>.of(UsualSpend(category: chai, amount: Money.fromMajor(20)));
  final Option<SpendPreview> fits = Option<SpendPreview>.of(FitsToday(Money.fromMajor(1370)));
  final Option<SpendPreview> over = Option<SpendPreview>.of(
    OverTodayShare(over: Money.fromMajor(99999999), tomorrow: Option<Money>.of(Money.fromMajor(88888888))),
  );

  EntryForm form({
    Option<UsualSpend> usual = const Option<UsualSpend>.none(),
    Option<SpendPreview> preview = const Option<SpendPreview>.none(),
  }) =>
      EntryForm(
        kind: EntryKind.spent,
        rupees: 0,
        date: WorkedExample.today,
        today: WorkedExample.today,
        earliestDate: WorkedExample.today,
        tiles: seedCategories,
        usual: usual,
        preview: preview,
      );

  setUp(() {
    services = FakeServices();
    bloc = AddEntryBloc(
      saveEntry: SaveEntry(ledger: services.ledger, recurring: services.recurring, clock: services.clock),
      deleteEntry: DeleteEntry(ledger: services.ledger),
      addOwnCategory: AddOwnCategory(categories: services.categories),
      haptics: services.haptics,
      clock: services.clock,
      categories: <Category>[...seedCategories, chai],
      usual: chaiTwenty,
    );
  });

  tearDown(() async {
    await bloc.close();
    await services.dispose();
  });

  Future<void> pump(
    WidgetTester tester,
    AddEntryState state, {
    double textScale = 1,
    Size size = TestWindows.phone,
    bool reduceMotion = false,
  }) =>
      pumpApp(
        tester,
        BlocProvider<AddEntryBloc>.value(
          value: bloc,
          child: Material(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(children: <Widget>[UsualSlot(state: state)]),
            ),
          ),
        ),
        textScale: textScale,
        size: size,
        reduceMotion: reduceMotion,
      );

  double slotHeight(WidgetTester tester) => tester.getSize(find.byType(UsualSlot)).height;

  group('UsualSlot (FR-AD-1)', () {
    testWidgets('is 48dp with the pill, with the preview and with nothing', (WidgetTester tester) async {
      await pump(tester, AddEntryEditing(form(usual: chaiTwenty)));
      expect(slotHeight(tester), 48);
      await pump(tester, AddEntryEditing(form(preview: fits)));
      expect(slotHeight(tester), 48);
      await pump(tester, AddEntryEditing(form()));
      expect(slotHeight(tester), 48);
    });

    testWidgets('shows the pill or the preview, never both', (WidgetTester tester) async {
      await pump(tester, AddEntryEditing(form(usual: chaiTwenty, preview: fits)));
      expect(find.byType(UsualPill), findsOneWidget);
      expect(find.byType(SpendPreviewLine), findsNothing);
      await pump(tester, AddEntryEditing(form(preview: fits)));
      expect(find.byType(UsualPill), findsNothing);
      expect(find.text('Leaves ₹1,370 for today'), findsOneWidget);
    });

    testWidgets('the preview is centred in the slot', (WidgetTester tester) async {
      await pump(tester, AddEntryEditing(form(preview: fits)));
      expect(tester.getCenter(find.byType(SpendPreviewLine)).dy, tester.getCenter(find.byType(UsualSlot)).dy);
    });

    testWidgets('at 2× text a three-line preview grows the slot and nothing overflows (NFR-4)', (WidgetTester tester) async {
      await pump(tester, AddEntryEditing(form(preview: over)), textScale: 2, size: TestWindows.smallPhone);
      expect(slotHeight(tester), greaterThanOrEqualTo(3 * 40));
      expect(tester.takeException(), isNull);
    });

    for (final double scale in <double>[1, 1.5, 2]) {
      testWidgets('at ₹0 the slot is the same height with and without the pill at $scale× text', (WidgetTester tester) async {
        await pump(tester, AddEntryEditing(form(usual: chaiTwenty)), textScale: scale);
        expect(find.byType(AnimatedContainer), findsOneWidget);
        final double withPill = slotHeight(tester);
        await pump(tester, AddEntryEditing(form()), textScale: scale);
        await tester.pumpAndSettle();
        expect(slotHeight(tester), withPill);
        expect(withPill, 48);
      });
    }

    testWidgets('a pill too wide to show leaves the slot at 48dp', (WidgetTester tester) async {
      final Option<UsualSpend> wide = Option<UsualSpend>.of(
        UsualSpend(category: chai.copyWith(customName: 'Wwwwwwwwwwwwwwww'), amount: Money.fromMajor(999999999)),
      );
      await pump(tester, AddEntryEditing(form(usual: wide)), textScale: 2, size: TestWindows.smallPhone);
      expect(find.byType(AnimatedContainer), findsNothing);
      expect(slotHeight(tester), 48);
    });

    testWidgets('swaps with a 150ms crossfade, under reduced motion too (FR-AD-10 AC-3)', (WidgetTester tester) async {
      await pump(tester, AddEntryEditing(form(usual: chaiTwenty)));
      expect(tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration, const Duration(milliseconds: 150));
      await pump(tester, AddEntryEditing(form(usual: chaiTwenty)), reduceMotion: true);
      expect(tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration, HisaabMotion.reducedCrossfade);
    });

    testWidgets('the pill is plain while editing, ink while saving and once finished (FR-AD-10 AC-4)', (WidgetTester tester) async {
      await pump(tester, AddEntryEditing(form(usual: chaiTwenty)));
      expect(tester.widget<UsualPill>(find.byType(UsualPill)).filled, isFalse);
      await pump(tester, AddEntrySaving(form(usual: chaiTwenty), categoryId: chai.id));
      expect(tester.widget<UsualPill>(find.byType(UsualPill)).filled, isTrue);
      await pump(tester, AddEntryFinished(form(usual: chaiTwenty), categoryId: chai.id));
      expect(tester.widget<UsualPill>(find.byType(UsualPill)).filled, isTrue);
    });

    testWidgets("a failed save reads Couldn't save. Try again. in the pill (FR-AD-10 AC-4)", (WidgetTester tester) async {
      await pump(tester, AddEntryEditing(form(usual: chaiTwenty), failed: true));
      expect(tester.widget<UsualPill>(find.byType(UsualPill)).failed, isTrue);
      expect(find.text("Couldn't save. Try again.", findRichText: true), findsOneWidget);
      expect(slotHeight(tester), 48);
    });

    testWidgets('a tap on the pill asks the bloc to save the usual (FR-AD-10 AC-4)', (WidgetTester tester) async {
      await pump(tester, bloc.state);
      await tester.tap(find.byType(UsualPill));
      await tester.settle();
      expect(bloc.state, isA<AddEntryFinished>());
      expect(services.ledger.saved.single.categoryId, chai.id);
    });
  });
}
