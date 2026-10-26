import 'package:equatable/equatable.dart';

import '../../../core/time/calendar_date.dart';
import 'occurrence.dart';

/// One run of the recurring engine: the entries to post and where each rule's `next_due` moves.
final class RecurringPosting extends Equatable {
  const RecurringPosting({required this.occurrences, required this.nextDueByRuleId});

  final List<Occurrence> occurrences;

  /// The new `next_due` of every rule that had something due.
  final Map<int, CalendarDate> nextDueByRuleId;

  bool get isEmpty => occurrences.isEmpty;

  @override
  List<Object?> get props => <Object?>[occurrences, nextDueByRuleId];
}
