import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import 'bill_icon.dart';

/// What the user gave for a fixed monthly bill in Settings: its name, amount, due day and icon.
final class BillInput extends Equatable {
  const BillInput({
    required this.label,
    required this.amount,
    required this.dueDay,
    this.icon = const Option<BillIcon>.none(),
  });

  /// The bill's name, e.g. "Electricity".
  final String label;
  final Money amount;

  /// Day of the month it goes out, 1–31; clamped in short months like paydays (SPEC BR-1).
  final int dueDay;

  /// The icon the user picked; none follows the name (D118).
  final Option<BillIcon> icon;

  @override
  List<Object?> get props => <Object?>[label, amount, dueDay, icon];
}
