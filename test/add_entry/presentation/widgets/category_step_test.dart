import 'package:expense_tracker/add_entry/presentation/bloc/add_entry_bloc.dart';
import 'package:expense_tracker/add_entry/presentation/bloc/add_entry_state.dart';
import 'package:expense_tracker/add_entry/presentation/widgets/category_step.dart';
import 'package:expense_tracker/core/design/hisaab_colors.dart';
import 'package:expense_tracker/core/widgets/category_tile.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('while saving, the tapped tile is flashed ink and no tile takes taps (FR-AD-5, FR-AD-6)', (WidgetTester tester) async {
    final FakeServices services = FakeServices();
    addTearDown(services.dispose);
    final AddEntryBloc bloc = await tester.buildBloc(
      () => AddEntryBloc(
        saveEntry: SaveEntry(ledger: services.ledger, recurring: services.recurring, clock: services.clock),
        deleteEntry: DeleteEntry(ledger: services.ledger),
        haptics: services.haptics,
        clock: services.clock,
        categories: seedCategories,
      ),
    );
    addTearDown(bloc.close);
    final EntryForm form = EntryForm(
      kind: EntryKind.spent,
      rupees: 60,
      date: WorkedExample.today,
      today: WorkedExample.today,
      earliestDate: WorkedExample.today,
      tiles: seedCategories.where((Category c) => c.kind == EntryKind.spent).toList(),
      step: AddEntryStep.category,
    );
    await pumpApp(
      tester,
      BlocProvider<AddEntryBloc>.value(
        value: bloc,
        child: Scaffold(body: CategoryStep(state: AddEntrySaving(form, categoryId: SeedCategoryIds.food))),
      ),
    );
    final CategoryTile food = tester.widget<CategoryTile>(find.byKey(const ValueKey<String>('tile-food')));
    expect(food.flashed, isTrue);
    expect(food.onPressed, isNull);
    final Container surface = tester.widget<Container>(
      find.descendant(of: find.byKey(const ValueKey<String>('tile-food')), matching: find.byType(Container)).first,
    );
    expect((surface.decoration! as ShapeDecoration).color, HisaabColors.light.ink);
  });

  group('chip row alignment', () {
    Future<void> pumpStep(WidgetTester tester, {Option<Entry> editing = const Option<Entry>.none(), Size size = TestWindows.phone, double textScale = 1}) async {
      final FakeServices services = FakeServices();
      addTearDown(services.dispose);
      final AddEntryBloc bloc = await tester.buildBloc(
        () => AddEntryBloc(
          saveEntry: SaveEntry(ledger: services.ledger, recurring: services.recurring, clock: services.clock),
          deleteEntry: DeleteEntry(ledger: services.ledger),
          haptics: services.haptics,
          clock: services.clock,
          categories: seedCategories,
        ),
      );
      addTearDown(bloc.close);
      final EntryForm form = EntryForm(
        kind: EntryKind.spent,
        rupees: 60,
        date: WorkedExample.today,
        today: WorkedExample.today,
        earliestDate: WorkedExample.today.addDays(-30),
        tiles: seedCategories.where((Category c) => c.kind == EntryKind.spent).toList(),
        step: AddEntryStep.category,
        editing: editing,
      );
      await pumpApp(
        tester,
        BlocProvider<AddEntryBloc>.value(value: bloc, child: Scaffold(body: CategoryStep(state: AddEntryEditing(form)))),
        size: size,
        textScale: textScale,
      );
    }

    double tilesLeft(WidgetTester tester) => tester.getTopLeft(find.byKey(const ValueKey<String>('tile-food'))).dx;
    double tilesRight(WidgetTester tester) => tester.getTopRight(find.byKey(const ValueKey<String>('tile-bills'))).dx;

    for (final (String name, Size size, double scale) in <(String, Size, double)>[
      ('a phone', TestWindows.phone, 1),
      ('a 320dp phone at 1.5× text', TestWindows.smallPhone, 1.5),
    ]) {
      testWidgets('the date and note chips span exactly the tiles\' width on $name', (WidgetTester tester) async {
        await pumpStep(tester, size: size, textScale: scale);
        expect(tester.getTopLeft(find.byKey(const ValueKey<String>('date-chip'))).dx, tilesLeft(tester));
        expect(tester.getTopRight(find.byKey(const ValueKey<String>('note-chip'))).dx, tilesRight(tester));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Back draws a 40dp well on the tiles\' left edge, inside a 48dp tap target', (WidgetTester tester) async {
      await pumpStep(tester);
      final Finder well = find.byKey(const ValueKey<String>('back-to-amount-well'));
      expect(tester.getSize(find.byKey(const ValueKey<String>('back-to-amount'))), const Size(48, 48));
      expect(tester.getSize(well), const Size(40, 40));
      expect(tester.getTopLeft(well).dx, tilesLeft(tester));
    });

    testWidgets('the open note field also ends on the tiles\' edge', (WidgetTester tester) async {
      await pumpStep(tester);
      await tester.tap(find.byKey(const ValueKey<String>('note-chip')));
      await tester.pump();
      expect(tester.getTopRight(find.byKey(const ValueKey<String>('note-field'))).dx, tilesRight(tester));
    });

    testWidgets('editing: Delete starts its own line on the tiles\' left edge', (WidgetTester tester) async {
      await pumpStep(tester, editing: Option<Entry>.of(WorkedExample.entries[3]));
      final Offset delete = tester.getTopLeft(find.byKey(const ValueKey<String>('delete-entry')));
      expect(delete.dx, tilesLeft(tester));
      expect(delete.dy, greaterThan(tester.getBottomLeft(find.byKey(const ValueKey<String>('note-chip'))).dy));
      expect(tester.getTopRight(find.byKey(const ValueKey<String>('note-chip'))).dx, tilesRight(tester));
    });

    testWidgets('editing fits all three chips on a 320dp phone at 2× text', (WidgetTester tester) async {
      await pumpStep(tester, editing: Option<Entry>.of(WorkedExample.entries[3]), size: TestWindows.smallPhone, textScale: 2);
      expect(tester.takeException(), isNull);
      expect(tester.getTopRight(find.byKey(const ValueKey<String>('note-chip'))).dx, tilesRight(tester));
    });
  });
}
