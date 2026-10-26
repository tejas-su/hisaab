import 'package:equatable/equatable.dart';

import 'entry_kind.dart';

/// A fixed bucket for entries, such as Food or Salary (SPEC BR-11).
///
/// The seed list never changes order or count; the user may only rename it or change its icon.
final class Category extends Equatable {
  const Category({
    required this.id,
    required this.key,
    required this.iconKey,
    required this.kind,
    required this.sort,
    this.customName,
  });

  final int id;

  /// Stable seed key (see [CategoryKeys]); the UI localises it unless [customName] is set.
  final String key;
  final String iconKey;

  /// Whether entries in this category are *Spent* or *Got*.
  final EntryKind kind;

  /// Fixed position in the grid (0-based within [kind]).
  final int sort;

  /// The user's rename, if any.
  final String? customName;

  @override
  List<Object?> get props => <Object?>[id, key, iconKey, kind, sort, customName];
}

/// The seed category keys (SPEC BR-11), matching the v1 migration.
abstract final class CategoryKeys {
  static const String home = 'home';
  static const String bills = 'bills';
  static const String salary = 'salary';
}
