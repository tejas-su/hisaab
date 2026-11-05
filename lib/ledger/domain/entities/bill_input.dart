import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import 'amount_mode.dart';
import 'bill_icon.dart';

/// What the user gave for a monthly bill in Settings: its name, amount, due day, icon and how
/// its amount behaves.
final class BillInput extends Equatable {
  const BillInput({
    required this.label,
    required this.amount,
    required this.dueDay,
    this.icon = const Option<BillIcon>.none(),
    this.amountMode = AmountMode.fixed,
  });

  /// The bill's name, e.g. "Electricity".
  final String label;
  final Money amount;

  /// Day of the month it goes out, 1–31; clamped in short months like paydays (SPEC BR-1).
  final int dueDay;

  /// The icon the user picked; none follows the name (D118).
  final Option<BillIcon> icon;

  /// Whether the amount is fixed, changes, or is a card bill; read by [EditBill] (D123).
  final AmountMode amountMode;

  @override
  List<Object?> get props => <Object?>[label, amount, dueDay, icon, amountMode];
}
