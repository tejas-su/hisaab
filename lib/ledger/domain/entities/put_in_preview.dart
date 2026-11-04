import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';

/// What putting an extra amount into savings today does to the days left (D120).
sealed class PutInPreview extends Equatable {
  const PutInPreview();
}

/// Each day after today gets [less] less: "Each day till payday gets ₹62 less".
final class EachDayLess extends PutInPreview {
  const EachDayLess(this.less);

  final Money less;

  @override
  List<Object?> get props => <Object?>[less];
}

/// Today is the cycle's last day, so there are no later days to split it over (E-h).
final class PaydayTomorrow extends PutInPreview {
  const PaydayTomorrow();

  @override
  List<Object?> get props => const <Object?>[];
}
