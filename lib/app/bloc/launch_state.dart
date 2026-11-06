import 'package:equatable/equatable.dart';

import '../../core/errors/failure.dart';

/// Which root screen the app shows.
sealed class LaunchState extends Equatable {
  const LaunchState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Reading whether onboarding was finished; the background shows, nothing else.
final class LaunchLoading extends LaunchState {
  const LaunchLoading();
}

/// First run, or onboarding was left midway (SPEC FR-ON-1, FR-ON-6).
final class LaunchNeedsOnboarding extends LaunchState {
  const LaunchNeedsOnboarding();
}

/// Home and Spends. [assemble] plays the "blocks assemble" entrance once, after onboarding (FR-ON-5).
///
/// [generation] grows each time the data is replaced (D139); the root keys Home with it, so Home's
/// blocs are built afresh. It is left out of equality: the bloc reaches each new generation
/// through [LaunchLoading], so two ready states never need telling apart.
final class LaunchReady extends LaunchState {
  const LaunchReady({this.assemble = false, this.generation = 0});

  final bool assemble;
  final int generation;

  @override
  List<Object?> get props => <Object?>[assemble];
}

/// The preference couldn't be read; the startup failure message shows.
final class LaunchFailed extends LaunchState {
  const LaunchFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}
