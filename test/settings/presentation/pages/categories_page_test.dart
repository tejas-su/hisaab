import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/pump_app.dart';

void main() {
  late FakeCategoryRepository repository;
  late CategoriesBloc bloc;

  setUp(() {
    repository = FakeCategoryRepository();
    bloc = CategoriesBloc(
      categories: repository,
      addOwnCategory: AddOwnCategory(categories: repository),
      renameCategory: RenameCategory(categories: repository),
      changeCategoryIcon: ChangeCategoryIcon(categories: repository),
      setCategoryHidden: SetCategoryHidden(categories: repository),
    );
  });

  tearDown(() => bloc.close());

  Future<void> open(WidgetTester tester, {Size size = TestWindows.phone}) async {
    await pumpApp(tester, BlocProvider<CategoriesBloc>.value(value: bloc, child: const CategoriesPage()), size: size);
    bloc.add(const CategoriesLoadRequested());
    await tester.settle();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.settle();
  }

  group('CategoriesPage (FR-SE-2, D138)', () {
    testWidgets('lists Your own with Add, the 8 built-in ones, then Money in', (WidgetTester tester) async {
      await open(tester);
      expect(find.text('Your own'), findsOneWidget);
      expect(find.text('0 of 4'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('add-category')), findsOneWidget);
      for (final String key in <String>['food', 'travel', 'shopping', 'bills', 'fun', 'health', 'home', 'other', 'salary', 'other_income']) {
        expect(find.byKey(ValueKey<String>('category-$key')), findsOneWidget, reason: key);
      }
    });

    testWidgets('a built-in category\'s sheet has Name and Icon but no Hide', (WidgetTester tester) async {
      await open(tester);
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-food')));
      expect(find.byKey(const ValueKey<String>('category-name-row')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('category-icon-row')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('hide-category')), findsNothing);
      expect(find.text('Built in. You can rename it or change its icon. It always keeps its place.'), findsOneWidget);
    });

    testWidgets('renaming a built-in one shows the new name and what it was built in as', (WidgetTester tester) async {
      await open(tester);
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-food')));
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-name-row')));
      await tester.enterText(find.byKey(const ValueKey<String>('category-name-field')), 'Khana');
      await tester.pump();
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-name-save')));

      expect(find.text('Built in as Food. The new name shows on its past entries too.'), findsOneWidget);
      expect(repository.categories.first.customName, 'Khana');
    });

    testWidgets('a taken name says so and saves nothing', (WidgetTester tester) async {
      await open(tester);
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-food')));
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-name-row')));
      await tester.enterText(find.byKey(const ValueKey<String>('category-name-field')), 'Travel');
      await tester.pump();
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-name-save')));

      expect(find.text('Another category is already called that.'), findsOneWidget);
      expect(repository.categories.first.customName, isNull);
    });

    testWidgets('changing an icon goes back to the sheet with the new icon', (WidgetTester tester) async {
      await open(tester);
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-food')));
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-icon-row')));
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('icon-chai')));

      expect(find.byKey(const ValueKey<String>('category-name-row')), findsOneWidget);
      expect(repository.categories.first.iconKey, 'chai');
    });

    testWidgets('Add a category picks the icon from the name and adds it under Your own', (WidgetTester tester) async {
      await open(tester);
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('add-category')));
      await tester.enterText(find.byKey(const ValueKey<String>('category-name-field')), 'Petrol');
      await tester.pump();
      expect(find.text('Icon from the name: Fuel'), findsOneWidget);
      expect(find.text('Add Petrol'), findsOneWidget);

      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-name-save')));

      expect(find.byKey(const ValueKey<String>('category-name-field')), findsNothing);
      expect(find.text('Petrol'), findsOneWidget);
      expect(find.text('1 of 4', skipOffstage: false), findsOneWidget);
      expect(repository.categories.last.iconKey, 'fuel');
    });

    testWidgets('adding a name that is already shown is not offered', (WidgetTester tester) async {
      await open(tester);
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('add-category')));
      await tester.enterText(find.byKey(const ValueKey<String>('category-name-field')), 'food');
      await tester.pump();
      expect(find.text('You have Food already. It saves there.'), findsOneWidget);
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-name-save')));
      expect(repository.categories.where((Category c) => c.isOwn), isEmpty);
    });

    testWidgets('Add a category can pick another icon first', (WidgetTester tester) async {
      await open(tester);
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('add-category')));
      await tester.enterText(find.byKey(const ValueKey<String>('category-name-field')), 'Petrol');
      await tester.pump();
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-add-icon-line')));
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('icon-car')));
      expect(find.text('Icon: Car'), findsOneWidget);
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-name-save')));
      expect(repository.categories.last.iconKey, 'car');
    });

    testWidgets('hiding one of the user\'s own offers Undo, which brings it back', (WidgetTester tester) async {
      await repository.addOwn(name: 'Petrol', iconKey: 'fuel').run();
      await open(tester);
      await tapAndSettle(tester, find.text('Petrol'));
      expect(find.text('Its entries stay in Spends. It leaves the Add tray.'), findsOneWidget);

      await tapAndSettle(tester, find.byKey(const ValueKey<String>('hide-category')));

      expect(find.text('Petrol hidden'), findsOneWidget);
      expect(find.text('0 of 4', skipOffstage: false), findsOneWidget);
      await tapAndSettle(tester, find.text('Undo'));
      expect(find.text('1 of 4', skipOffstage: false), findsOneWidget);
    });

    testWidgets('typing a hidden category\'s name offers to bring it back, from the keyboard too', (WidgetTester tester) async {
      final Category gym = (await repository.addOwn(name: 'Gym', iconKey: 'gym').run()).getOrElse((Failure f) => fail(f.message));
      await repository.setHidden(gym.id, hidden: true).run();
      await open(tester);
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('add-category')));
      await tester.enterText(find.byKey(const ValueKey<String>('category-name-field')), 'gym');
      await tester.pump();
      expect(find.text('Bring back Gym'), findsOneWidget);
      expect(find.text('You hid Gym. Saving brings it back.'), findsOneWidget);

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.settle();

      expect(repository.categories.singleWhere((Category c) => c.id == gym.id).hidden, isFalse);
    });

    testWidgets('a name with no matching icon says so', (WidgetTester tester) async {
      await open(tester);
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('add-category')));
      await tester.enterText(find.byKey(const ValueKey<String>('category-name-field')), 'Misc');
      await tester.pump();
      expect(find.text('Icon: Tag. No match yet'), findsOneWidget);
    });

    for (final (String why, String name, String message) in <(String, String, String)>[
      ('a name kept for the app', 'Savings', 'Use 1 to 16 letters, and not Savings or Card bill.'),
      ('a failed write', 'Khana', "Couldn't save. Try again."),
    ]) {
      testWidgets('renaming with $why says so', (WidgetTester tester) async {
        await open(tester);
        await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-food')));
        await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-name-row')));
        await tester.enterText(find.byKey(const ValueKey<String>('category-name-field')), name);
        await tester.pump();
        if (name == 'Khana') {
          repository.failure = DatabaseFailure('locked');
        }
        await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-name-save')));
        expect(find.text(message), findsOneWidget);
      });
    }

    testWidgets('back from the icon step returns to the sheet unchanged', (WidgetTester tester) async {
      await open(tester);
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-food')));
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-icon-row')));
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-sheet-back')));
      expect(find.byKey(const ValueKey<String>('category-icon-row')), findsOneWidget);
      expect(repository.categories.first.iconKey, 'food');
    });

    testWidgets('with 4 of the user\'s own, Add a category is gone', (WidgetTester tester) async {
      for (final String name in <String>['Petrol', 'Kids', 'Pets', 'Gym']) {
        await repository.addOwn(name: name, iconKey: 'tag').run();
      }
      await open(tester);
      expect(find.text('4 of 4'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('add-category')), findsNothing);
    });

    testWidgets('a failed load offers Try again', (WidgetTester tester) async {
      repository.failure = DatabaseFailure('locked');
      await open(tester);
      expect(find.text('Try again'), findsOneWidget);
      repository.failure = null;
      await tapAndSettle(tester, find.text('Try again'));
      expect(find.text('0 of 4'), findsOneWidget);
    });

    for (final (String name, Size size) in <(String, Size)>[
      ('phone', TestWindows.phone),
      ('phone landscape', TestWindows.phoneLandscape),
      ('small phone', TestWindows.smallPhone),
      ('foldable unfolded', TestWindows.foldableUnfolded),
      ('foldable landscape', TestWindows.foldableLandscape),
      ('tablet', TestWindows.tablet),
    ]) {
      testWidgets('the page and a sheet lay out without overflow on a $name', (WidgetTester tester) async {
        await open(tester, size: size);
        expect(tester.takeException(), isNull);
        await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-food')));
        await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-icon-row')));
        expect(tester.takeException(), isNull);
      });
    }
  });
}
