import 'package:hisaab/add_entry/add_entry.dart';
import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/money/money.dart';
import 'package:hisaab/core/usecases/use_case.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/fake_services.dart';
import '../../../helpers/fixtures/ledger/categories.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeServices services;
  late CycleSummary summary;

  setUp(() async {
    services = FakeServices();
    summary = (await services.getCycleSummary(const NoParams()).run()).getOrElse((Failure f) => fail(f.message));
  });

  tearDown(() => services.dispose());

  Future<void> openOnGrid(WidgetTester tester, {List<Category> categories = seedCategories, Size size = TestWindows.phone}) async {
    final AddEntryBloc bloc = AddEntryBloc(
      saveEntry: SaveEntry(ledger: services.ledger, recurring: services.recurring, clock: services.clock),
      deleteEntry: DeleteEntry(ledger: services.ledger),
      addOwnCategory: AddOwnCategory(categories: services.categories),
      haptics: services.haptics,
      clock: services.clock,
      categories: categories,
      summary: Option<CycleSummary>.of(summary),
    );
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (BuildContext context) =>
              Center(child: TextButton(onPressed: () => AddEntryTray.show(context, bloc), child: const Text('open'))),
        ),
      ),
      size: size,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    for (final String key in '250'.split('')) {
      await tester.tap(find.byKey(ValueKey<String>('keypad-$key')));
    }
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey<String>('add-next')));
    await tester.pumpAndSettle();
  }

  Future<void> openNameStep(WidgetTester tester, {Size size = TestWindows.phone}) async {
    await openOnGrid(tester, size: size);
    // why: in a short window (a phone on its side) row 3 sits below the fold of the scrolling tray.
    await tester.ensureVisible(find.byKey(const ValueKey<String>('new-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('new-category')));
    await tester.pumpAndSettle();
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
  }

  group('The New tile (FR-AD-9 AC-1)', () {
    testWidgets('sits after the 8 on Spent and reads "New category" to TalkBack', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await openOnGrid(tester);
      expect(find.bySemanticsLabel('New category'), findsOneWidget);
      expect(find.text('Your own'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the user\'s own sit on row 3 with New after them; hidden ones are gone', (WidgetTester tester) async {
      await openOnGrid(tester, categories: <Category>[
        ...seedCategories,
        const Category(id: 13, key: 'own_13', iconKey: 'fuel', kind: EntryKind.spent, sort: 8, customName: 'Petrol'),
        const Category(id: 14, key: 'own_14', iconKey: 'gym', kind: EntryKind.spent, sort: 9, customName: 'Gym', hidden: true),
      ]);
      expect(find.text('Petrol'), findsOneWidget);
      expect(find.text('Gym'), findsNothing);
      final double other = tester.getTopLeft(find.byKey(const ValueKey<String>('tile-other'))).dy;
      final double petrol = tester.getTopLeft(find.byKey(const ValueKey<String>('tile-own_13'))).dy;
      expect(petrol, greaterThan(other));
      expect(tester.getTopLeft(find.byKey(const ValueKey<String>('new-category'))).dy, petrol);
    });

    testWidgets('with 4 of the user\'s own, New gives way to one line', (WidgetTester tester) async {
      await openOnGrid(tester, categories: <Category>[
        ...seedCategories,
        for (int i = 0; i < 4; i++)
          Category(id: 20 + i, key: 'own_${20 + i}', iconKey: 'tag', kind: EntryKind.spent, sort: 8 + i, customName: 'Own $i'),
      ]);
      expect(find.byKey(const ValueKey<String>('new-category')), findsNothing);
      expect(find.text('4 of your own is the most. Hide one in Settings to make room.'), findsOneWidget);
    });
  });

  group('NewCategoryNameStep (FR-AD-9 AC-2 to AC-5)', () {
    testWidgets('opens with the amount, the question, a focused field and 6 name chips', (WidgetTester tester) async {
      await openNameStep(tester);
      expect(find.text('₹250'), findsOneWidget);
      expect(find.text("What's it called?"), findsOneWidget);
      expect(tester.widget<TextField>(find.byKey(const ValueKey<String>('new-category-name'))).autofocus, isTrue);
      expect(find.text('The name picks an icon'), findsOneWidget);
      for (final String name in <String>['Groceries', 'Kids', 'Family', 'Pets', 'Petrol', 'Salon']) {
        expect(find.byKey(ValueKey<String>('suggest-$name')), findsOneWidget);
      }
    });

    testWidgets('typing a name picks its icon, narrows the chips, and names the key', (WidgetTester tester) async {
      await openNameStep(tester);
      await tester.enterText(find.byKey(const ValueKey<String>('new-category-name')), 'Pet');
      await tester.pump();
      expect(find.byKey(const ValueKey<String>('suggest-Pets')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('suggest-Petrol')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('suggest-Kids')), findsNothing);
      expect(find.text('Icon from the name: Pet'), findsOneWidget);
      expect(find.text('Save in Pet'), findsOneWidget);
    });

    testWidgets('a chip fills the field', (WidgetTester tester) async {
      await openNameStep(tester);
      await tester.tap(find.byKey(const ValueKey<String>('suggest-Groceries')));
      await tester.pump();
      expect(find.widgetWithText(TextField, 'Groceries'), findsOneWidget);
      expect(find.text('Icon from the name: Groceries'), findsOneWidget);
    });

    testWidgets('a name with no match says so', (WidgetTester tester) async {
      await openNameStep(tester);
      await tester.enterText(find.byKey(const ValueKey<String>('new-category-name')), 'Misc');
      await tester.pump();
      expect(find.text('Icon: Tag. No match yet'), findsOneWidget);
    });

    testWidgets('a name that matches a built-in category says it saves there', (WidgetTester tester) async {
      await openNameStep(tester);
      await tester.enterText(find.byKey(const ValueKey<String>('new-category-name')), 'food');
      await tester.pump();
      expect(find.text('You have Food already. It saves there.'), findsOneWidget);
      expect(find.text('Save in Food'), findsOneWidget);
    });

    testWidgets('Save is disabled while the name is empty', (WidgetTester tester) async {
      await openNameStep(tester);
      await tester.tap(find.byKey(const ValueKey<String>('save-new-category')));
      await settle(tester);
      expect(services.ledger.saved, isEmpty);
      expect(find.text("What's it called?"), findsOneWidget);
    });

    testWidgets('Save in Petrol makes the category, saves ₹250 in it and closes the tray', (WidgetTester tester) async {
      await openNameStep(tester);
      await tester.enterText(find.byKey(const ValueKey<String>('new-category-name')), 'Petrol');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('save-new-category')));
      await settle(tester);

      final Category made = services.categories.categories.singleWhere((Category c) => c.isOwn);
      expect((made.customName, made.iconKey), ('Petrol', 'fuel'));
      expect(services.ledger.saved.single.categoryId, made.id);
      expect(services.ledger.saved.single.amount, Money.fromMajor(250));
      expect(find.byType(AddEntryTray), findsNothing);
    });

    testWidgets('a failed save keeps the name step with "Couldn\'t save. Try again."', (WidgetTester tester) async {
      await openNameStep(tester);
      await tester.enterText(find.byKey(const ValueKey<String>('new-category-name')), 'Petrol');
      await tester.pump();
      services.categories.failure = DatabaseFailure('locked');
      await tester.tap(find.byKey(const ValueKey<String>('save-new-category')));
      await settle(tester);
      expect(find.text("Couldn't save. Try again."), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Petrol'), findsOneWidget);
    });

    testWidgets('back returns to the grid with the amount kept', (WidgetTester tester) async {
      await openNameStep(tester);
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.text('What was it for?'), findsOneWidget);
      expect(find.text('₹250'), findsOneWidget);
    });

    testWidgets('the icon line opens the icon step; a pick comes back with the icon named', (WidgetTester tester) async {
      await openNameStep(tester);
      await tester.enterText(find.byKey(const ValueKey<String>('new-category-name')), 'Petrol');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey<String>('category-icon-line')));
      await tester.pumpAndSettle();
      expect(find.text('Pick an icon for Petrol'), findsOneWidget);
      expect(find.text('From the name: Fuel'), findsOneWidget);

      await tester.scrollUntilVisible(find.byKey(const ValueKey<String>('icon-gift')), 200, scrollable: find.byType(Scrollable).last);
      await tester.tap(find.byKey(const ValueKey<String>('icon-gift')));
      await tester.pumpAndSettle();

      expect(find.text('Icon: Gift'), findsOneWidget);
    });

    for (final (String name, Size size) in <(String, Size)>[
      ('phone', TestWindows.phone),
      ('phone landscape', TestWindows.phoneLandscape),
      ('small phone', TestWindows.smallPhone),
      ('foldable unfolded', TestWindows.foldableUnfolded),
      ('foldable landscape', TestWindows.foldableLandscape),
      ('tablet', TestWindows.tablet),
    ]) {
      testWidgets('the name and icon steps lay out without overflow on a $name', (WidgetTester tester) async {
        await openNameStep(tester, size: size);
        await tester.enterText(find.byKey(const ValueKey<String>('new-category-name')), 'Petrol');
        await tester.pump();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(find.byKey(const ValueKey<String>('category-icon-line')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey<String>('category-icon-line')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(const ValueKey<String>('icon-fuel')), findsOneWidget);
      });
    }
  });
}
