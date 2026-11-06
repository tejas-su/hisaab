import 'package:equatable/equatable.dart';

/// What drives the *Money coming in* row in Settings (SPEC FR-SE-1).
sealed class IncomeEvent extends Equatable {
  const IncomeEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Settings opened, or a rule or entry changed: load the income again.
final class IncomeLoadRequested extends IncomeEvent {
  const IncomeLoadRequested();
}
