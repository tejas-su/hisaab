import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';

/// One plain sentence about a cycle, with one next step (SPEC BR-14). At most 3 are shown.
sealed class Insight extends Equatable {
  const Insight();
}

/// A category is up at least 20% and ₹1,000 on last cycle at the same day-of-cycle (BR-14 #1).
final class CategoryUp extends Insight {
  const CategoryUp({required this.categoryId, required this.rise});

  final int categoryId;

  /// How much more was spent than last cycle by the same day.
  final Money rise;

  @override
  List<Object?> get props => <Object?>[categoryId, rise];
}

/// One entry over twice its category's median entry this cycle (BR-14 #2).
final class BiggestSpend extends Insight {
  const BiggestSpend({required this.categoryId, required this.amount, required this.date});

  final int categoryId;
  final Money amount;
  final CalendarDate date;

  @override
  List<Object?> get props => <Object?>[categoryId, amount, date];
}

/// The category whose weekly spending varies least, with at least 4 entries (BR-14 #3).
final class SteadiestCategory extends Insight {
  const SteadiestCategory({required this.categoryId});

  final int categoryId;

  @override
  List<Object?> get props => <Object?>[categoryId];
}

/// "Use these limits?": last cycle's spending as per-category limits (BR-12, BR-14 #4).
final class LimitOffer extends Insight {
  const LimitOffer({required this.limits});

  /// The suggested limit by category id.
  final Map<int, Money> limits;

  @override
  List<Object?> get props => <Object?>[limits];
}
