import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../ledger/ledger.dart';
import 'categories_event.dart';
import 'categories_state.dart';

/// Owns Settings › Categories (FR-SE-2, D138): loads every category and saves renames, icons,
/// hiding with Undo, and new categories of the user's own, reloading the list after each.
///
/// Created by the route; the page adds [CategoriesLoadRequested] when it opens.
class CategoriesBloc extends Bloc<CategoriesEvent, CategoriesState> {
  CategoriesBloc({
    required this._categories,
    required this._addOwnCategory,
    required this._renameCategory,
    required this._changeCategoryIcon,
    required this._setCategoryHidden,
  }) : super(const CategoriesLoading()) {
    on<CategoriesLoadRequested>((CategoriesLoadRequested event, Emitter<CategoriesState> emit) => _reload(emit), transformer: restartable());
    on<CategoryRenameRequested>(
      (CategoryRenameRequested event, Emitter<CategoriesState> emit) => _write(
        emit,
        _renameCategory(CategoryRename(id: event.id, name: event.name, labels: event.labels)).map((Unit _) => event.id),
      ),
      transformer: droppable(),
    );
    on<CategoryIconChangeRequested>(
      (CategoryIconChangeRequested event, Emitter<CategoriesState> emit) =>
          _write(emit, _changeCategoryIcon(CategoryIconChange(id: event.id, iconKey: event.iconKey)).map((Unit _) => event.id)),
      transformer: droppable(),
    );
    on<CategoryHideRequested>(_onHideRequested, transformer: droppable());
    on<CategoryHideUndone>(
      (CategoryHideUndone event, Emitter<CategoriesState> emit) =>
          _write(emit, _setCategoryHidden(CategoryVisibility(id: event.id, hidden: false)).map((Unit _) => event.id)),
      transformer: droppable(),
    );
    on<CategoryAddRequested>(
      (CategoryAddRequested event, Emitter<CategoriesState> emit) => _write(
        emit,
        _addOwnCategory(NewCategory(name: event.name, iconKey: event.iconKey, labels: event.labels)).map((Category c) => c.id),
      ),
      transformer: droppable(),
    );
  }

  final CategoryRepository _categories;
  final AddOwnCategory _addOwnCategory;
  final RenameCategory _renameCategory;
  final ChangeCategoryIcon _changeCategoryIcon;
  final SetCategoryHidden _setCategoryHidden;

  Future<void> _reload(Emitter<CategoriesState> emit) async => (await _categories.all().run()).match(
        (Failure _) => emit(const CategoriesFailed()),
        (List<Category> categories) => emit(CategoriesReady(categories)),
      );

  Future<void> _onHideRequested(CategoryHideRequested event, Emitter<CategoriesState> emit) async {
    await _write(emit, _setCategoryHidden(CategoryVisibility(id: event.id, hidden: true)).map((Unit _) => event.id));
    final CategoriesState current = state;
    if (current is CategoriesReady && current.problem.isNone()) {
      final Category? hidden = current.categories.where((Category c) => c.id == event.id).firstOrNull;
      emit(CategoriesReady(current.categories, savedId: current.savedId, undo: Option<Category>.fromNullable(hidden)));
    }
  }

  /// Runs [write], then reloads and names the saved category, or keeps the list and says why not.
  Future<void> _write(Emitter<CategoriesState> emit, TaskEither<Failure, int> write) async {
    final CategoriesState current = state;
    if (current is! CategoriesReady) {
      return;
    }
    await (await write.run()).match(
      (Failure failure) async {
        AppLogger.log(tag: 'categories.save_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
        emit(CategoriesReady(current.categories, problem: Option<CategoryProblem>.of(_problemOf(failure))));
      },
      (int id) async => (await _categories.all().run()).match(
        (Failure _) => emit(CategoriesReady(current.categories, problem: const Option<CategoryProblem>.of(CategoryProblem.failed))),
        (List<Category> categories) => emit(CategoriesReady(categories, savedId: Option<int>.of(id))),
      ),
    );
  }

  static CategoryProblem _problemOf(Failure failure) => switch (failure) {
        CategoryNameTakenFailure() => CategoryProblem.nameTaken,
        OwnCategoryLimitFailure() => CategoryProblem.full,
        InvalidCategoryNameFailure() => CategoryProblem.invalidName,
        _ => CategoryProblem.failed,
      };
}
