import 'package:equatable/equatable.dart';

/// What the Settings *Daily nudge* switch is built from (SPEC FR-SE-7): the user's answer and
/// whether the phone allows notifications.
final class NudgeSwitch extends Equatable {
  const NudgeSwitch({required this.answeredYes, required this.enabled});

  /// The user said yes (the ask sheet or the switch).
  final bool answeredYes;

  /// The phone allows notifications.
  final bool enabled;

  /// The switch reads on only with both.
  bool get on => answeredYes && enabled;

  /// The user said yes but the phone's notifications are off now (E122): the switch reads off
  /// with the refusal line.
  bool get blocked => answeredYes && !enabled;

  @override
  List<Object?> get props => <Object?>[answeredYes, enabled];
}
