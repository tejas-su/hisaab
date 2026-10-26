import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';

/// What the user typed for a fixed monthly bill in Settings: its name, amount and due day.
final class BillInput extends Equatable {
  const BillInput({required this.label, required this.amount, required this.dueDay});

  /// The bill's name, e.g. "Electricity".
  final String label;
  final Money amount;

  /// Day of the month it goes out, 1–31; clamped in short months like paydays (SPEC BR-1).
  final int dueDay;

  @override
  List<Object?> get props => <Object?>[label, amount, dueDay];
}
