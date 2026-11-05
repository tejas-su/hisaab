import 'package:equatable/equatable.dart';

/// What the user does on the bill amount sheet (D123).
sealed class BillAmountEvent extends Equatable {
  const BillAmountEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The sheet opened; load what was entered last time.
final class BillAmountLoadRequested extends BillAmountEvent {
  const BillAmountLoadRequested();
}

/// A digit key ([key] is '0'–'9' or '00').
final class BillAmountKeyPressed extends BillAmountEvent {
  const BillAmountKeyPressed(this.key);

  final String key;

  @override
  List<Object?> get props => <Object?>[key];
}

/// ⌫: drop the last digit.
final class BillAmountBackspacePressed extends BillAmountEvent {
  const BillAmountBackspacePressed();
}

/// A long-press on ⌫: clear the amount.
final class BillAmountCleared extends BillAmountEvent {
  const BillAmountCleared();
}

/// *Save*: enter the amount.
final class BillAmountSavePressed extends BillAmountEvent {
  const BillAmountSavePressed();
}

/// *Didn't go out this month*: skip the occurrence.
final class BillAmountSkipPressed extends BillAmountEvent {
  const BillAmountSkipPressed();
}
