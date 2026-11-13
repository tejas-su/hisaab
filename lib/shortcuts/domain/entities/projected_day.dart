import 'package:equatable/equatable.dart';

import '../../../ledger/ledger.dart';

/// One day as the widget will show it: Home's summary for that day, worked out ahead of time on
/// the assumption that nothing new is typed (SPEC FR-WG-5).
final class ProjectedDay extends Equatable {
  const ProjectedDay({required this.summary, required this.spends});

  /// The day's [CycleSummary], exactly as `GetCycleSummary` returns it on that day.
  final CycleSummary summary;

  /// The day's typed *Spent* entries, oldest first: today's bites. Empty on every later day.
  final List<Entry> spends;

  @override
  List<Object?> get props => <Object?>[summary, spends];
}
