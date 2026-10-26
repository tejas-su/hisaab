import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import 'bill_kind.dart';

/// A fixed monthly bill picked during onboarding: what, how much and on which day.
final class BillDraft extends Equatable {
  const BillDraft({required this.kind, required this.amount, required this.dueDay});

  final BillKind kind;
  final Money amount;

  /// Day of the month it goes out, 1–31; clamped in short months like paydays.
  final int dueDay;

  @override
  List<Object?> get props => <Object?>[kind, amount, dueDay];
}
