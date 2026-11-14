import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../ledger/ledger.dart';

/// What an opened row of *Where it went* shows (SPEC FR-SP-4 AC-R2, BR-21): its change against the
/// cycle before, its biggest entries and how many it has.
final class CategoryDetail extends Equatable {
  const CategoryDetail({required this.change, required this.top, required this.count});

  /// The category's change by the same day; [None] when the cycle before was not fully tracked.
  final Option<Money> change;

  /// Up to 3 *Spent* entries, biggest first.
  final List<Entry> top;

  /// All the category's *Spent* entries in the cycle.
  final int count;

  @override
  List<Object?> get props => <Object?>[change, top, count];
}
