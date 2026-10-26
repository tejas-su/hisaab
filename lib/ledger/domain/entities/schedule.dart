import 'package:equatable/equatable.dart';

import '../../../core/time/calendar_date.dart';
import 'frequency.dart';

/// When a recurring rule falls due: a [frequency] counted from an [anchor] date.
final class Schedule extends Equatable {
  const Schedule({required this.frequency, required this.anchor, this.lastDayOfMonth = false});

  final Frequency frequency;

  /// A real occurrence whose day of month, weekday or 14-day phase fixes the pattern. For a
  /// monthly rule on the 31st it is a date in a 31-day month, so the day isn't lost to clamping.
  final CalendarDate anchor;

  /// For monthly rules: due on the last day of every month instead of the anchor's day.
  final bool lastDayOfMonth;

  @override
  List<Object?> get props => <Object?>[frequency, anchor, lastDayOfMonth];
}
