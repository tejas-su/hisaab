import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';

/// Money left over from yesterday's share, now spread over the days to payday (SPEC BR-8).
final class YesterdaySaving extends Equatable {
  const YesterdaySaving({required this.saved, required this.eachDayMore});

  /// Yesterday's share minus yesterday's spending; always above ₹0.
  final Money saved;

  /// How much each day's share grew because of [saved], floored to the rupee; may be ₹0.
  final Money eachDayMore;

  @override
  List<Object?> get props => <Object?>[saved, eachDayMore];
}
