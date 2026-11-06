import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_row.dart';
import '../../../core/db/db_schema.dart';
import '../../../core/errors/failure.dart';

/// A row of the `categories` table (`custom_name` is the user's rename, `budget_minor` its limit,
/// `archived` 1 when hidden).
final class CategoryModel extends Equatable {
  const CategoryModel({
    required this.id,
    required this.key,
    required this.iconKey,
    required this.kind,
    required this.sort,
    this.customName,
    this.budgetMinor,
    this.archived = false,
  });

  /// Reads a `categories` row.
  ///
  /// Returns [Right] with the model, or [Left] with [InvalidDataFailure] for a bad column.
  static Either<Failure, CategoryModel> fromRow(Map<String, Object?> row) => readRow(
        Tables.categories,
        () => CategoryModel(
          id: row.intAt(CategoryColumns.id),
          key: row.stringAt(CategoryColumns.key),
          customName: row.stringOrNullAt(CategoryColumns.customName),
          iconKey: row.stringAt(CategoryColumns.iconKey),
          kind: row.stringAt(CategoryColumns.kind),
          sort: row.intAt(CategoryColumns.sort),
          budgetMinor: row.intOrNullAt(CategoryColumns.budgetMinor),
          archived: row.intAt(CategoryColumns.archived) == 1,
        ),
      );

  final int id;
  final String key;
  final String? customName;
  final String iconKey;
  final String kind;
  final int sort;
  final int? budgetMinor;
  final bool archived;

  @override
  List<Object?> get props => <Object?>[id, key, customName, iconKey, kind, sort, budgetMinor, archived];
}
