import 'package:equatable/equatable.dart';

import '../../../core/errors/failure.dart';
import '../../../ledger/ledger.dart';

/// The *Money coming in* row's situation (SPEC FR-SE-1).
sealed class IncomeState extends Equatable {
  const IncomeState();
}

/// The income is still loading; the row shows its label only.
final class IncomeLoading extends IncomeState {
  const IncomeLoading();

  @override
  List<Object?> get props => <Object?>[];
}

/// The income is loaded; the row shows it and opens the income sheet.
final class IncomeReady extends IncomeState {
  const IncomeReady(this.income);

  final Income income;

  @override
  List<Object?> get props => <Object?>[income];
}

/// The income couldn't be read; the row shows its label only and doesn't open.
final class IncomeFailed extends IncomeState {
  const IncomeFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}
