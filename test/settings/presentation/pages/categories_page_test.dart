import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/core/widgets/hisaab_snackbar_bar.dart';
import 'package:hisaab/core/widgets/hisaab_snackbar_host.dart';
import 'package:hisaab/habits/habits.dart';
import 'package:hisaab/l10n/gen/app_localizations.dart';
import 'package:hisaab/ledger/ledger.dart';
import 'package:hisaab/settings/presentation/widgets/category_sheet.dart';
import 'package:hisaab/settings/settings.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fakes/fake_clock.dart';
import '../../../helpers/fakes/fake_ledger_repository.dart';
import '../../../helpers/fakes/fake_suggestion_state_repository.dart';
import '../../../helpers/fixtures/habits/chai_habit.dart';
import '../../../helpers/fixtures/ledger/worked_example.dart';
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

  group('CategoriesPage your usual (FR-SE-2 AC-6, D153)', () {
    const ValueKey<String> chaiRow = ValueKey<String>('category-own_13');
    const ValueKey<String> usualKey = ValueKey<String>('your-usual-row');
    const ValueKey<String> forgetKey = ValueKey<String>('usual-forget');
    late FakeLedgerRepository ledger;
    late FakeSuggestionStateRepository states;
    late FakeClock clock;

    setUp(() {
      repository.categories.add(chai);
      ledger = FakeLedgerRepository(chaiWeekdays(today: WorkedExample.today));
      states = FakeSuggestionStateRepository();
      clock = FakeClock(DateTime(2026, 10, 26, 10, 5));
    });

    tearDown(() => ledger.dispose());

    /// The row as the app's route builds it: one bloc per sheet, loaded at once.
    Widget usualRow(Category category) => BlocProvider<UsualRowBloc>(
          key: ValueKey<int>(category.id),
          create: (BuildContext _) => UsualRowBloc(
            categoryId: category.id,
            getIndex: GetHabitIndex(ledger: ledger, categories: repository, states: states, clock: clock),
            forget: ForgetUsual(states: states, clock: clock),
            restore: RestoreUsual(states: states),
            clock: clock,
          )..add(const UsualRowLoadRequested()),
          child: Builder(
            builder: (BuildContext context) => YourUsualRow(name: category.labelIn(AppLocalizations.of(context))),
          ),
        );

    Future<void> openWith(
      WidgetTester tester, {
      Widget Function(Category category)? row,
      Size size = TestWindows.phone,
      double textScale = 1,
    }) async {
      await pumpApp(
        tester,
        BlocProvider<CategoriesBloc>.value(value: bloc, child: CategoriesPage(usualRow: row)),
        size: size,
        textScale: textScale,
      );
      bloc.add(const CategoriesLoadRequested());
      await tester.settle();
    }

    testWidgets('without usualRow the sheet is as before', (WidgetTester tester) async {
      await openWith(tester);
      await tapAndSettle(tester, find.byKey(chaiRow));
      expect(find.byKey(usualKey), findsNothing);
      expect(find.byKey(const ValueKey<String>('category-name-row')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('hide-category')), findsOneWidget);
    });

    testWidgets('the row sits under Name and Icon and above Hide', (WidgetTester tester) async {
      await openWith(tester, row: usualRow);
      await tapAndSettle(tester, find.byKey(chaiRow));

      final Rect icon = tester.getRect(find.byKey(const ValueKey<String>('category-icon-row')));
      final Rect usual = tester.getRect(find.byKey(usualKey));
      final Rect note = tester.getRect(find.text('Worked out on this phone from what you add.'));
      final Rect hide = tester.getRect(find.byKey(const ValueKey<String>('hide-category')));
      expect(find.text('₹20, weekdays around 10 am'), findsOneWidget);
      expect(usual.top, icon.bottom + 12);
      expect((usual.left, usual.right), (icon.left, icon.right));
      expect(note.top, greaterThan(usual.bottom));
      expect(hide.top, greaterThan(note.bottom));
    });

    testWidgets('a category with no habit has the sheet it had', (WidgetTester tester) async {
      await openWith(tester);
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-food')));
      final double plain = tester.getTopLeft(find.text('Built in. You can rename it or change its icon. It always keeps its place.')).dy;
      Navigator.of(tester.element(find.byType(CategorySheet))).pop();
      await tester.settle();

      await openWith(tester, row: usualRow);
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-food')));

      expect(find.byKey(usualKey), findsNothing);
      expect(tester.getTopLeft(find.text('Built in. You can rename it or change its icon. It always keeps its place.')).dy, plain);
    });

    testWidgets("a Got category's sheet never gets the row", (WidgetTester tester) async {
      Widget marker(Category category) => Text('usual of ${category.key}');
      await openWith(tester, row: marker);

      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-food')));
      expect(find.text('usual of food'), findsOneWidget);
      Navigator.of(tester.element(find.byType(CategorySheet))).pop();
      await tester.settle();

      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-salary')));
      expect(find.byType(CategorySheet), findsOneWidget);
      expect(find.text('usual of salary'), findsNothing);
    });

    testWidgets('Add a category gets no row', (WidgetTester tester) async {
      Widget marker(Category category) => Text('usual of ${category.key}');
      await openWith(tester, row: marker);
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('add-category')));
      expect(find.textContaining('usual of'), findsNothing);
    });

    testWidgets('Forget removes the row and shows Forgotten with Undo inside the sheet; Undo brings it back (E68)', (WidgetTester tester) async {
      await openWith(tester, row: usualRow);
      await tapAndSettle(tester, find.byKey(chaiRow));
      await tapAndSettle(tester, find.byKey(forgetKey));

      expect(find.byKey(usualKey), findsNothing);
      expect(find.byKey(const ValueKey<String>('category-name-row')), findsOneWidget, reason: 'the sheet stays open');
      final Finder bar = find.descendant(of: find.byType(CategorySheet), matching: find.byType(HisaabSnackbarBar));
      expect(bar, findsOneWidget);
      expect(find.descendant(of: bar, matching: find.text('Forgotten')), findsOneWidget);
      expect(tester.getRect(bar).bottom, tester.getRect(find.byType(CategorySheet)).bottom - 24);
      expect(states.states[chai.id]?.forgottenAt.isSome(), isTrue);

      await tapAndSettle(tester, find.descendant(of: bar, matching: find.text('Undo')));

      expect(find.byKey(usualKey), findsOneWidget);
      expect(states.states, isEmpty);
    });

    testWidgets('Forgotten leaves after 4 s and the row stays gone', (WidgetTester tester) async {
      await openWith(tester, row: usualRow);
      await tapAndSettle(tester, find.byKey(chaiRow));
      await tapAndSettle(tester, find.byKey(forgetKey));

      await tester.pump(HisaabSnackbarHost.visibleFor);
      await tester.settle();

      expect(find.text('Forgotten'), findsNothing);
      expect(find.byKey(usualKey), findsNothing);
      expect(find.byKey(const ValueKey<String>('category-name-row')), findsOneWidget);
    });

    testWidgets('leaving the summary closes the Forgotten bar, so its Undo is never left without a row', (WidgetTester tester) async {
      await openWith(tester, row: usualRow);
      await tapAndSettle(tester, find.byKey(chaiRow));
      await tapAndSettle(tester, find.byKey(forgetKey));

      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-icon-row')));

      expect(find.byType(HisaabSnackbarBar), findsNothing);
      expect(tester.takeException(), isNull);
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-sheet-back')));
      expect(find.byKey(usualKey), findsNothing);
    });

    testWidgets('renaming in the sheet changes what Forget reads out', (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await openWith(tester, row: usualRow);
      await tapAndSettle(tester, find.byKey(chaiRow));
      expect(find.bySemanticsLabel('Forget your usual Chai'), findsOneWidget);

      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-name-row')));
      await tester.enterText(find.byKey(const ValueKey<String>('category-name-field')), 'Cutting');
      await tester.pump();
      await tapAndSettle(tester, find.byKey(const ValueKey<String>('category-name-save')));

      expect(find.bySemanticsLabel('Forget your usual Cutting'), findsOneWidget);
      expect(find.bySemanticsLabel('Forget your usual Chai'), findsNothing);
      handle.dispose();
    });

    testWidgets('the sheet with the row fits 320dp at 2× text, and the Forgotten bar stays inside the sheet', (WidgetTester tester) async {
      await openWith(tester, row: usualRow, size: TestWindows.smallPhone, textScale: 2);
      await tapAndSettle(tester, find.byKey(chaiRow));
      expect(tester.takeException(), isNull);
      await tapAndSettle(tester, find.byKey(forgetKey));

      final Rect sheet = tester.getRect(find.byType(CategorySheet));
      final Rect bar = tester.getRect(find.byType(HisaabSnackbarBar));
      expect(tester.takeException(), isNull);
      expect(bar.top, greaterThanOrEqualTo(sheet.top));
      expect(bar.bottom, sheet.bottom - 24);
    });

    for (final (String name, Size size) in <(String, Size)>[
      ('phone', TestWindows.phone),
      ('phone landscape', TestWindows.phoneLandscape),
      ('small phone', TestWindows.smallPhone),
      ('foldable unfolded', TestWindows.foldableUnfolded),
      ('foldable landscape', TestWindows.foldableLandscape),
      ('tablet', TestWindows.tablet),
    ]) {
      testWidgets('the sheet with the row lays out without overflow on a $name', (WidgetTester tester) async {
        await openWith(tester, row: usualRow, size: size);
        await tapAndSettle(tester, find.byKey(chaiRow));
        expect(find.byKey(usualKey, skipOffstage: false), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  });
}
