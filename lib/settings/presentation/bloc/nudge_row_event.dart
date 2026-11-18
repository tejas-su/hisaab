import 'package:equatable/equatable.dart';

/// What happens on Settings' *Daily nudge* row (SPEC FR-SE-7).
sealed class NudgeRowEvent extends Equatable {
  const NudgeRowEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Settings opened: read the answer and whether the phone still allows notifications.
final class NudgeRowLoadRequested extends NudgeRowEvent {
  const NudgeRowLoadRequested();
}

/// The user flipped the switch; [on] is the position it was flipped to.
final class NudgeRowToggled extends NudgeRowEvent {
  const NudgeRowToggled({required this.on});

  final bool on;

  @override
  List<Object?> get props => <Object?>[on];
}
