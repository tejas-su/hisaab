import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';

/// One day of this week so far, as it stood on that day: what was spent, against the share the
/// day had (SPEC BR-6a). Drives the hero's *This week* bars (FR-HO-2).
final class WeekDay extends Equatable {
  const WeekDay({required this.date, required this.spent, required this.share});

  final CalendarDate date;

  /// *Spent* entries dated [date].
  final Money spent;

  /// `A` for [date], rebuilt from the ledger as it is now: entries dated on or before [date],
  /// with bills posted after it still counted as due (BR-3, BR-4).
  final Money share;

  @override
  List<Object?> get props => <Object?>[date, spent, share];
}
