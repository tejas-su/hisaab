import 'package:equatable/equatable.dart';

import '../../../core/time/calendar_date.dart';

/// The stamp on a bill in the bill sheet (SPEC BR-9, D118).
sealed class BillStamp extends Equatable {
  const BillStamp();
}

/// The bill goes out in [days] days, within the due-soon window.
final class BillStampDue extends BillStamp {
  const BillStampDue(this.days);

  /// Whole days until it goes out; 1 means tomorrow.
  final int days;

  @override
  List<Object?> get props => <Object?>[days];
}

/// This month's bill was counted as spent [on] that date by the recurring engine.
final class BillStampCounted extends BillStamp {
  const BillStampCounted(this.on);

  final CalendarDate on;

  @override
  List<Object?> get props => <Object?>[on];
}

/// Neither due soon nor counted this month, e.g. a bill added after its day (D33).
final class BillStampNone extends BillStamp {
  const BillStampNone();

  @override
  List<Object?> get props => <Object?>[];
}

/// Where a fixed bill stands today: its next date and its stamp.
final class BillStatus extends Equatable {
  const BillStatus({required this.nextDate, required this.daysAway, required this.stamp});

  /// The next date the engine will post it.
  final CalendarDate nextDate;

  /// Whole days from today to [nextDate].
  final int daysAway;
  final BillStamp stamp;

  @override
  List<Object?> get props => <Object?>[nextDate, daysAway, stamp];
}
