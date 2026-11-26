import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../ledger/ledger.dart';

/// A saving whose set-aside amount has met its target, for Home's reached line (SPEC BR-23, FR-HO-3).
final class ReachedLine extends Equatable {
  const ReachedLine({required this.saving, required this.target, required this.pending});

  /// The saving the line names; its sheet opens on a tap.
  final RecurringRule saving;

  /// The target that was reached, the only amount the line shows.
  final Money target;

  /// True until the line has been on screen for [target]: it is then written as shown.
  final bool pending;

  /// Picks the line's candidate among the active [rules], with [setAside] by rule id, on [today].
  ///
  /// A saving at or above its target is *shown today* when it was written for that target today,
  /// and *pending* when it was never written for that target. The one shown today wins, so it keeps
  /// the slot all day (F2); else the first pending saving, the rule saved first (E144). Returns none
  /// when no saving qualifies.
  static Option<ReachedLine> pick({required List<RecurringRule> rules, required Map<int, Money> setAside, required CalendarDate today}) {
    final List<ReachedLine> reached = rules
        .where((RecurringRule rule) => rule.kind == EntryKind.saved)
        .map((RecurringRule rule) => _reached(rule, setAside[rule.id] ?? Money.zero))
        .nonNulls
        .toList()
      ..sort((ReachedLine a, ReachedLine b) => a.saving.id.compareTo(b.saving.id));
    final Option<ReachedLine> shown = Option<ReachedLine>.fromNullable(
      reached.where((ReachedLine line) => !line.pending && line.saving.targetReachedOn == Option<CalendarDate>.of(today)).firstOrNull,
    );
    return shown.alt(() => Option<ReachedLine>.fromNullable(reached.where((ReachedLine line) => line.pending).firstOrNull));
  }

  static ReachedLine? _reached(RecurringRule saving, Money setAside) => saving.target
      .filter((Money target) => setAside.compareTo(target) >= 0)
      .map((Money target) => ReachedLine(saving: saving, target: target, pending: saving.targetReachedFor != Option<Money>.of(target)))
      .toNullable();

  @override
  List<Object?> get props => <Object?>[saving, target, pending];
}
