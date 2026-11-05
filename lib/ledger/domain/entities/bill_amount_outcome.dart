import 'package:equatable/equatable.dart';

import '../usecase/enter_bill_amount.dart';
import 'bill_skip.dart';
import 'occurrence.dart';

/// What the bill amount sheet did with a waiting bill, for Home's snackbar and Undo (D123).
sealed class BillAmountOutcome extends Equatable {
  const BillAmountOutcome();
}

/// The amount was entered.
final class BillAmountWasEntered extends BillAmountOutcome {
  const BillAmountWasEntered(this.entered);

  final BillAmountEntered entered;

  @override
  List<Object?> get props => <Object?>[entered];
}

/// "Didn't go out this month": [occurrence] was skipped as [skip].
final class BillAmountWasSkipped extends BillAmountOutcome {
  const BillAmountWasSkipped({required this.occurrence, required this.skip});

  final Occurrence occurrence;
  final BillSkip skip;

  @override
  List<Object?> get props => <Object?>[occurrence, skip];
}
