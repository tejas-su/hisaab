import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';

/// Everything ever put into savings, and the day of the first saving (D120): "₹42,000 put in
/// since Jan". It is what went in, never what a saving is worth.
final class SavedTotal extends Equatable {
  const SavedTotal({required this.total, required this.since});

  final Money total;

  /// The date of the earliest *Saved* entry.
  final CalendarDate since;

  @override
  List<Object?> get props => <Object?>[total, since];
}
