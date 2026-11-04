import 'package:equatable/equatable.dart';

import '../../../ledger/ledger.dart';

/// The localised names to store on the rules onboarding creates (the domain has no l10n).
final class SetupLabels extends Equatable {
  const SetupLabels({required this.income, required this.bills, this.startingGuess});

  /// Name of the income rule, e.g. "Money in".
  final String income;

  /// Name of each bill rule, e.g. "Rent".
  final Map<BillKind, String> bills;

  /// Note on the *It changes* income entry, e.g. "Starting guess"; null leaves it without one.
  final String? startingGuess;

  @override
  List<Object?> get props => <Object?>[income, bills, startingGuess];
}
