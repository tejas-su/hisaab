import 'package:equatable/equatable.dart';

/// The *Delete everything* page's situation (SPEC FR-SE-4).
sealed class DeleteEverythingState extends Equatable {
  const DeleteEverythingState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Waiting for the hold. [failures] counts failed deletes, so each one shows its message.
final class DeleteEverythingIdle extends DeleteEverythingState {
  const DeleteEverythingIdle({this.failures = 0});

  final int failures;

  @override
  List<Object?> get props => <Object?>[failures];
}

/// Deleting; the key is busy and nothing else can be tapped.
final class DeleteEverythingWorking extends DeleteEverythingState {
  const DeleteEverythingWorking();
}

/// Everything is gone; the app goes back to onboarding.
final class DeleteEverythingDone extends DeleteEverythingState {
  const DeleteEverythingDone();
}
