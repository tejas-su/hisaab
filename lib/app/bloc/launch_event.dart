import 'package:equatable/equatable.dart';

/// What moves the app between its root screens.
sealed class LaunchEvent extends Equatable {
  const LaunchEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The app opened; read whether onboarding was finished.
final class LaunchStarted extends LaunchEvent {
  const LaunchStarted();
}

/// The onboarding page saved everything; show the app.
final class LaunchOnboardingFinished extends LaunchEvent {
  const LaunchOnboardingFinished();
}

/// A restore, an undo or *Delete everything* replaced the data under the app (D139); read
/// onboarding again and rebuild the root screen from scratch.
final class LaunchDataReplaced extends LaunchEvent {
  const LaunchDataReplaced();
}
