import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
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
    this.limit = const Option<Money>.none(),
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

  /// The optional spending limit for one cycle; off by default (SPEC BR-12).
  final Option<Money> limit;

  @override
  List<Object?> get props => <Object?>[id, key, iconKey, kind, sort, customName, limit];
}

/// The seed category keys (SPEC BR-11), matching the v1 migration.
abstract final class CategoryKeys {
  static const String home = 'home';
  static const String bills = 'bills';
  static const String salary = 'salary';

  /// The hidden category every *Saved* entry and saving rule uses; never shown (D120).
  static const String saved = 'saved';

  /// The hidden category every card bill uses; never shown (D123).
  static const String cardPaid = 'card_paid';
}
