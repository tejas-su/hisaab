import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import 'entry_kind.dart';

/// A bucket for entries, such as Food or Salary (SPEC BR-11).
///
/// The built-in list never changes order or count; the user may rename any category, change
/// its icon, and add up to 4 *Spent* ones of their own after the built-in ones (D138).
final class Category extends Equatable {
  const Category({
    required this.id,
    required this.key,
    required this.iconKey,
    required this.kind,
    required this.sort,
    this.customName,
    this.limit = const Option<Money>.none(),
    this.hidden = false,
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

  /// Whether the user hid this category of their own: it leaves the Add tray and Settings,
  /// but its entries keep its name and icon (D138).
  final bool hidden;

  /// Whether the user made this category, rather than it being built in (D138).
  bool get isOwn => key.startsWith(CategoryKeys.ownPrefix);

  /// A copy with the given name, icon or hidden flag changed.
  Category copyWith({String? customName, String? iconKey, bool? hidden}) => Category(
        id: id,
        key: key,
        iconKey: iconKey ?? this.iconKey,
        kind: kind,
        sort: sort,
        customName: customName ?? this.customName,
        limit: limit,
        hidden: hidden ?? this.hidden,
      );

  @override
  List<Object?> get props => <Object?>[id, key, iconKey, kind, sort, customName, limit, hidden];
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

  /// The start of every key of a category the user made (`own_12`); no built-in key has it (D138).
  static const String ownPrefix = 'own_';
}

/// Limits on the categories a user can add (SPEC BR-11, D138).
abstract final class OwnCategories {
  /// The most shown at once; hidden ones don't count.
  static const int max = 4;

  /// The longest name, after trimming, that fits a tile at 1.5× text.
  static const int maxNameLength = 16;
}
