import 'package:equatable/equatable.dart';

import '../../../ledger/ledger.dart';

/// The localised names to store on the rules onboarding creates (the domain has no l10n).
final class SetupLabels extends Equatable {
  const SetupLabels({required this.income, required this.bills});

  /// Name of the salary rule, e.g. "Salary".
  final String income;

  /// Name of each bill rule, e.g. "Rent".
  final Map<BillKind, String> bills;

  @override
  List<Object?> get props => <Object?>[income, bills];
}
