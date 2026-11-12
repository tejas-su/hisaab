import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../ledger/ledger.dart';

/// The one spend the Add tray offers as *your usual*: a tap saves [amount] in [category] (SPEC
/// BR-17, FR-AD-10).
final class UsualSpend extends Equatable {
  /// Creates the suggestion of [amount] in [category].
  const UsualSpend({required this.category, required this.amount});

  /// The category to save in, as the tray shows it now, so its label follows a rename.
  final Category category;

  /// The habit's amount, exactly as the user logged it: never rounded, averaged or raised.
  final Money amount;

  @override
  List<Object?> get props => <Object?>[category, amount];
}
