import 'package:equatable/equatable.dart';

/// What happens on the month story route (SPEC FR-SP-7).
sealed class MonthStoryEvent extends Equatable {
  const MonthStoryEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The story opened, or Try again was tapped; load it.
final class MonthStoryLoadRequested extends MonthStoryEvent {
  const MonthStoryLoadRequested();
}
