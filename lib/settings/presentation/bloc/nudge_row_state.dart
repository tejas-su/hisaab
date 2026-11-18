import 'package:equatable/equatable.dart';

/// What the *Daily nudge* row shows (SPEC FR-SE-7).
sealed class NudgeRowState extends Equatable {
  const NudgeRowState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Still reading the answer; the row isn't shown yet.
final class NudgeRowLoading extends NudgeRowState {
  const NudgeRowLoading();
}

/// The row with its switch at [on]. [refused] adds the "Allow notifications" line under it after
/// Android refused the permission (AC-2, E122). [changes] counts the answers written, so the page
/// can re-arm the nudges after each one.
final class NudgeRowReady extends NudgeRowState {
  const NudgeRowReady({required this.on, this.refused = false, this.changes = 0});

  final bool on;
  final bool refused;
  final int changes;

  @override
  List<Object?> get props => <Object?>[on, refused, changes];
}
