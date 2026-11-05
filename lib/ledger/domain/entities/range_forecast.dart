import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/pay_cycle.dart';

/// What the BR-7 forecast is computed from: [remaining] is `P − S_today − Sv_extra_today`, and
/// [paceSpentBefore] is `V_prev`, the typed *Spent* entries before [today].
typedef ForecastInputs = ({PayCycle cycle, CalendarDate today, Money remaining, Money paceSpentBefore});

/// The range line's forecast: will the money last until payday at the current pace (SPEC BR-7)?
sealed class RangeForecast extends Equatable {
  const RangeForecast();

  @override
  List<Object?> get props => <Object?>[];
}

/// Fewer than 3 days of history, so there is no pace yet.
final class TooEarlyToForecast extends RangeForecast {
  const TooEarlyToForecast();
}

/// At this pace the money lasts, with about [spare] left at payday (rounded to ₹100).
final class LastsTillPayday extends RangeForecast {
  const LastsTillPayday(this.spare);

  final Money spare;

  @override
  List<Object?> get props => <Object?>[spare];
}

/// At this pace the money runs out on [date].
final class RunsOut extends RangeForecast {
  const RunsOut(this.date);

  final CalendarDate date;

  @override
  List<Object?> get props => <Object?>[date];
}
