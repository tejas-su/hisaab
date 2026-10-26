import 'package:expense_tracker/add_entry/presentation/cubit/add_entry_cubit.dart';
import 'package:expense_tracker/add_entry/presentation/cubit/add_entry_state.dart';
import 'package:expense_tracker/add_entry/presentation/widgets/category_step.dart';
import 'package:expense_tracker/core/design/hisaab_colors.dart';
import 'package:expense_tracker/core/widgets/category_tile.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('while saving, the tapped tile is flashed ink and no tile takes taps (FR-AD-5, FR-AD-6)', (WidgetTester tester) async {
    final FakeServices services = FakeServices();
    addTearDown(services.dispose);
    final AddEntryCubit cubit = AddEntryCubit(
      saveEntry: SaveEntry(ledger: services.ledger, clock: services.clock),
      deleteEntry: DeleteEntry(ledger: services.ledger),
      haptics: services.haptics,
      clock: services.clock,
      categories: seedCategories,
    );
    addTearDown(cubit.close);
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
      BlocProvider<AddEntryCubit>.value(
        value: cubit,
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
}
