import 'package:expense_tracker/core/errors/failure.dart';
import 'package:expense_tracker/ledger/ledger.dart';
import 'package:expense_tracker/settings/presentation/bloc/categories_bloc.dart';
import 'package:expense_tracker/settings/presentation/bloc/categories_event.dart';
import 'package:expense_tracker/settings/presentation/bloc/categories_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_category_repository.dart';
import '../../../helpers/fixtures/ledger/categories.dart';

void main() {
  late FakeCategoryRepository repository;
  final Map<int, String> labels = <int, String>{SeedCategoryIds.food: 'Food', SeedCategoryIds.travel: 'Travel'};

  setUp(() => repository = FakeCategoryRepository());

  CategoriesBloc build() {
    final CategoriesBloc bloc = CategoriesBloc(
      categories: repository,
      addOwnCategory: AddOwnCategory(categories: repository),
      renameCategory: RenameCategory(categories: repository),
      changeCategoryIcon: ChangeCategoryIcon(categories: repository),
      setCategoryHidden: SetCategoryHidden(categories: repository),
    );
    addTearDown(bloc.close);
    return bloc;
  }

  CategoriesReady ready(CategoriesBloc bloc) => bloc.state as CategoriesReady;

  group('CategoriesBloc (FR-SE-2, D138)', () {
    test('starts loading, then lists every category', () async {
      final CategoriesBloc bloc = build();
      expect(bloc.state, isA<CategoriesLoading>());
      await bloc.dispatch(const CategoriesLoadRequested());
      expect(ready(bloc).categories, seedCategories);
    });

    test('a failed load is CategoriesFailed', () async {
      repository.failure = DatabaseFailure('locked');
      final CategoriesBloc bloc = build();
      await bloc.dispatch(const CategoriesLoadRequested());
      expect(bloc.state, isA<CategoriesFailed>());
    });

    test('adding one lists it and names it as just saved', () async {
      final CategoriesBloc bloc = build();
      await bloc.dispatch(const CategoriesLoadRequested());

      await bloc.dispatch(CategoryAddRequested(name: 'Petrol', iconKey: 'fuel', labels: labels));

      final Category petrol = ready(bloc).categories.singleWhere((Category c) => c.isOwn);
      expect(petrol.customName, 'Petrol');
      expect(ready(bloc).savedId, Option<int>.of(petrol.id));
      expect(ready(bloc).problem, const Option<CategoryProblem>.none());
    });

    test('adding a fifth is refused as full', () async {
      final CategoriesBloc bloc = build();
      await bloc.dispatch(const CategoriesLoadRequested());
      for (final String name in <String>['Petrol', 'Kids', 'Pets', 'Gym', 'Salon']) {
        await bloc.dispatch(CategoryAddRequested(name: name, iconKey: 'tag', labels: labels));
      }
      expect(ready(bloc).problem, Option<CategoryProblem>.of(CategoryProblem.full));
      expect(ready(bloc).categories.where((Category c) => c.isOwn), hasLength(4));
    });

    test('renaming shows the new name', () async {
      final CategoriesBloc bloc = build();
      await bloc.dispatch(const CategoriesLoadRequested());

      await bloc.dispatch(CategoryRenameRequested(id: SeedCategoryIds.food, name: 'Khana', labels: labels));

      expect(ready(bloc).categories.first.customName, 'Khana');
      expect(ready(bloc).savedId, const Option<int>.of(SeedCategoryIds.food));
    });

    test('a taken name is refused and nothing changes', () async {
      final CategoriesBloc bloc = build();
      await bloc.dispatch(const CategoriesLoadRequested());

      await bloc.dispatch(CategoryRenameRequested(id: SeedCategoryIds.food, name: 'travel', labels: labels));

      expect(ready(bloc).problem, Option<CategoryProblem>.of(CategoryProblem.nameTaken));
      expect(ready(bloc).categories.first.customName, isNull);
    });

    test('an invalid name is refused', () async {
      final CategoriesBloc bloc = build();
      await bloc.dispatch(const CategoriesLoadRequested());
      await bloc.dispatch(CategoryRenameRequested(id: SeedCategoryIds.food, name: 'Savings', labels: labels));
      expect(ready(bloc).problem, Option<CategoryProblem>.of(CategoryProblem.invalidName));
    });

    test('changing an icon shows the new icon', () async {
      final CategoriesBloc bloc = build();
      await bloc.dispatch(const CategoriesLoadRequested());
      await bloc.dispatch(const CategoryIconChangeRequested(id: SeedCategoryIds.food, iconKey: 'chai'));
      expect(ready(bloc).categories.first.iconKey, 'chai');
    });

    test('hiding offers Undo once, and Undo brings it back', () async {
      final CategoriesBloc bloc = build();
      await bloc.dispatch(const CategoriesLoadRequested());
      await bloc.dispatch(CategoryAddRequested(name: 'Petrol', iconKey: 'fuel', labels: labels));
      final Category petrol = ready(bloc).categories.singleWhere((Category c) => c.isOwn);

      await bloc.dispatch(CategoryHideRequested(petrol.id));
      expect(ready(bloc).undo.toNullable()?.id, petrol.id);
      expect(ready(bloc).categories.singleWhere((Category c) => c.id == petrol.id).hidden, isTrue);

      await bloc.dispatch(CategoryHideUndone(petrol.id));
      expect(ready(bloc).undo, const Option<Category>.none());
      expect(ready(bloc).categories.singleWhere((Category c) => c.id == petrol.id).hidden, isFalse);
    });

    test('a write that fails reports failed and keeps the list', () async {
      final CategoriesBloc bloc = build();
      await bloc.dispatch(const CategoriesLoadRequested());
      repository.failure = DatabaseFailure('locked');

      await bloc.dispatch(const CategoryIconChangeRequested(id: SeedCategoryIds.food, iconKey: 'chai'));

      expect(ready(bloc).problem, Option<CategoryProblem>.of(CategoryProblem.failed));
      expect(ready(bloc).categories, seedCategories);
    });

    test('a write before the list has loaded does nothing', () async {
      final CategoriesBloc bloc = build();
      await bloc.dispatch(const CategoryIconChangeRequested(id: SeedCategoryIds.food, iconKey: 'chai'));
      expect(bloc.state, isA<CategoriesLoading>());
    });
  });

  test('a list that fails to reload after a write keeps the old list and says it failed', () async {
    final FakeCategoryRepository flaky = FakeCategoryRepository()..readsBeforeFailure = 1;
    final CategoriesBloc bloc = CategoriesBloc(
      categories: flaky,
      addOwnCategory: AddOwnCategory(categories: flaky),
      renameCategory: RenameCategory(categories: flaky),
      changeCategoryIcon: ChangeCategoryIcon(categories: flaky),
      setCategoryHidden: SetCategoryHidden(categories: flaky),
    );
    addTearDown(bloc.close);
    await bloc.dispatch(const CategoriesLoadRequested());

    await bloc.dispatch(const CategoryIconChangeRequested(id: SeedCategoryIds.food, iconKey: 'chai'));

    expect((bloc.state as CategoriesReady).problem, Option<CategoryProblem>.of(CategoryProblem.failed));
    expect((bloc.state as CategoriesReady).categories, seedCategories);
  });

  test('events and states compare by their fields', () {
    expect(const CategoryHideRequested(1), const CategoryHideRequested(1));
    expect(const CategoryHideUndone(1), isNot(const CategoryHideUndone(2)));
    expect(const CategoryIconChangeRequested(id: 1, iconKey: 'a'), const CategoryIconChangeRequested(id: 1, iconKey: 'a'));
    expect(const CategoryRenameRequested(id: 1, name: 'A', labels: <int, String>{}),
        const CategoryRenameRequested(id: 1, name: 'A', labels: <int, String>{}));
    expect(const CategoryAddRequested(name: 'A', iconKey: 'a', labels: <int, String>{}),
        isNot(const CategoryAddRequested(name: 'B', iconKey: 'a', labels: <int, String>{})));
    expect(const CategoriesLoadRequested(), const CategoriesLoadRequested());
    expect(const CategoriesLoading(), const CategoriesLoading());
    expect(const CategoriesFailed(), const CategoriesFailed());
  });
}

