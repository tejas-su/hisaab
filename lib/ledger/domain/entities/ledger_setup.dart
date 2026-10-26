import 'package:equatable/equatable.dart';

import 'entry_draft.dart';
import 'recurring_draft.dart';

/// Everything onboarding writes in one go: the income and bill rules plus any opening entries.
final class LedgerSetup extends Equatable {
  const LedgerSetup({required this.rules, this.entries = const <EntryDraft>[]});

  final List<RecurringDraft> rules;

  /// Entries with no rule behind them, e.g. this month's income when it "changes" each month.
  final List<EntryDraft> entries;

  @override
  List<Object?> get props => <Object?>[rules, entries];
}
