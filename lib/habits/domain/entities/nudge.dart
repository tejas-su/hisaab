import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/time/calendar_date.dart';
import '../nudge_rules.dart';

/// One daily nudge to arm: the date, the category it asks about and when it shows (SPEC BR-22).
final class Nudge extends Equatable {
  /// Creates the nudge of [date] that shows at [at].
  const Nudge({required this.date, required this.categoryId, required this.at});

  /// The local day it shows on.
  final CalendarDate date;

  /// The category it asks about; [None] for the general nudge (BR-22.2).
  final Option<int> categoryId;

  /// When it shows, in local time.
  final DateTime at;

  /// The notification id: the same date and category always give the same id, so arming twice
  /// never shows two.
  ///
  /// It is [NudgeRules.idOffset] + days since 2020-01-01 × 1000 + the category id (0 for the
  /// general nudge). Only one nudge is planned a date, so folding a category id above 999 into
  /// the date's 1000 ids cannot make two nudges of one date share an id.
  int get id =>
      NudgeRules.idOffset +
      NudgeRules.idEpoch.daysUntil(date) * NudgeRules.idSlotsPerDate +
      categoryId.getOrElse(() => NudgeRules.generalCategoryId) % NudgeRules.idSlotsPerDate;

  @override
  List<Object?> get props => <Object?>[date, categoryId, at];
}
