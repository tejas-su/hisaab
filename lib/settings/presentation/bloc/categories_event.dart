import 'package:equatable/equatable.dart';

/// What the user does on Settings › Categories (FR-SE-2, D138).
sealed class CategoriesEvent extends Equatable {
  const CategoriesEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The page opened, or *Try again* was tapped.
final class CategoriesLoadRequested extends CategoriesEvent {
  const CategoriesLoadRequested();
}

/// The user typed a new name for category [id]. [labels] holds each category's shown name by id.
final class CategoryRenameRequested extends CategoriesEvent {
  const CategoryRenameRequested({required this.id, required this.name, required this.labels});

  final int id;
  final String name;
  final Map<int, String> labels;

  @override
  List<Object?> get props => <Object?>[id, name, labels];
}

/// The user picked the icon [iconKey] for category [id].
final class CategoryIconChangeRequested extends CategoriesEvent {
  const CategoryIconChangeRequested({required this.id, required this.iconKey});

  final int id;
  final String iconKey;

  @override
  List<Object?> get props => <Object?>[id, iconKey];
}

/// The user tapped *Hide {name}* on one of their own.
final class CategoryHideRequested extends CategoriesEvent {
  const CategoryHideRequested(this.id);

  final int id;

  @override
  List<Object?> get props => <Object?>[id];
}

/// The user tapped *Undo* after hiding category [id].
final class CategoryHideUndone extends CategoriesEvent {
  const CategoryHideUndone(this.id);

  final int id;

  @override
  List<Object?> get props => <Object?>[id];
}

/// The user tapped *Add {name}* in *Add a category*. [labels] holds each category's shown name by id.
final class CategoryAddRequested extends CategoriesEvent {
  const CategoryAddRequested({required this.name, required this.iconKey, required this.labels});

  final String name;
  final String iconKey;
  final Map<int, String> labels;

  @override
  List<Object?> get props => <Object?>[name, iconKey, labels];
}
