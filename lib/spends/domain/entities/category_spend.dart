import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../ledger/ledger.dart';

/// One row of *Where it went*: a category, what was spent in it and its share (SPEC FR-SP-4).
final class CategorySpend extends Equatable {
  const CategorySpend({required this.category, required this.spent, required this.percent});

  /// The category, with its optional limit (BR-12).
  final Category category;
  final Money spent;

  /// Whole-number share of the cycle's spending; the rows always add up to 100 (BR-13).
  final int percent;

  @override
  List<Object?> get props => <Object?>[category, spent, percent];
}
