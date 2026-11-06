import 'package:fpdart/fpdart.dart';

import '../../core/errors/failure.dart';
import 'entities/category.dart';
import 'failures/ledger_failures.dart';

/// The rules for a category's name (SPEC BR-11, D138).
abstract final class CategoryName {
  // why: the export names of the hidden `saved` and `card_paid` categories (D120, D123); a
  // category of the same name would make CSV rows ambiguous.
  static const List<String> _reserved = <String>['savings', 'card bill'];

  /// Returns [Right] with [raw] trimmed, or [Left] with [InvalidCategoryNameFailure] when it is
  /// blank, longer than [OwnCategories.maxNameLength] characters, or reserved.
  static Either<Failure, String> validate(String raw) {
    final String name = raw.trim();
    if (name.isEmpty || name.runes.length > OwnCategories.maxNameLength) {
      return Either<Failure, String>.left(InvalidCategoryNameFailure('A name is 1–${OwnCategories.maxNameLength} characters'));
    }
    if (_reserved.contains(name.toLowerCase())) {
      return Either<Failure, String>.left(InvalidCategoryNameFailure('"$name" is kept for the app'));
    }
    return Either<Failure, String>.right(name);
  }

  /// The category in [categories] whose shown name equals [name], ignoring case and outer spaces.
  ///
  /// [labels] holds each category's shown name by id (built-in names are localised, so the
  /// caller supplies them); a category missing from it is matched by its own name.
  static Option<Category> match(String name, List<Category> categories, Map<int, String> labels) {
    final String wanted = name.trim().toLowerCase();
    return Option<Category>.fromNullable(
      categories
          .where((Category c) => (labels[c.id] ?? c.customName ?? c.key).trim().toLowerCase() == wanted)
          .firstOrNull,
    );
  }
}
