import 'package:expense_tracker/ledger/domain/entities/category.dart';
import 'package:expense_tracker/ledger/domain/entities/entry_kind.dart';

/// The seed categories exactly as migration v1 creates them (SPEC BR-11).
const List<Category> seedCategories = <Category>[
  Category(id: 1, key: 'food', iconKey: 'food', kind: EntryKind.spent, sort: 0),
  Category(id: 2, key: 'travel', iconKey: 'travel', kind: EntryKind.spent, sort: 1),
  Category(id: 3, key: 'shopping', iconKey: 'shopping', kind: EntryKind.spent, sort: 2),
  Category(id: 4, key: 'bills', iconKey: 'bills', kind: EntryKind.spent, sort: 3),
  Category(id: 5, key: 'fun', iconKey: 'fun', kind: EntryKind.spent, sort: 4),
  Category(id: 6, key: 'health', iconKey: 'health', kind: EntryKind.spent, sort: 5),
  Category(id: 7, key: 'home', iconKey: 'home', kind: EntryKind.spent, sort: 6),
  Category(id: 8, key: 'other', iconKey: 'other', kind: EntryKind.spent, sort: 7),
  Category(id: 9, key: 'salary', iconKey: 'salary', kind: EntryKind.got, sort: 0),
  Category(id: 10, key: 'other_income', iconKey: 'other_income', kind: EntryKind.got, sort: 1),
];

/// Category ids from [seedCategories].
abstract final class SeedCategoryIds {
  static const int food = 1;
  static const int travel = 2;
  static const int bills = 4;
  static const int home = 7;
  static const int salary = 9;
  static const int otherIncome = 10;

  /// The hidden `saved` category migration 003 seeds (D120).
  static const int saved = 11;
}
