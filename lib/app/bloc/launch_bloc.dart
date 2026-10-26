import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/errors/failure.dart';
import '../../core/logging/app_logger.dart';
import '../../settings/settings.dart';
import 'launch_event.dart';
import 'launch_state.dart';

/// Decides the root screen: onboarding or the app. Driven by [LaunchStarted] at launch and
/// [LaunchOnboardingFinished] from the onboarding page.
class LaunchBloc extends Bloc<LaunchEvent, LaunchState> {
  LaunchBloc({required this._preferences}) : super(const LaunchLoading()) {
    on<LaunchStarted>(_onStarted);
    on<LaunchOnboardingFinished>(_onOnboardingFinished);
  }

  final AppPreferencesRepository _preferences;

  Future<void> _onStarted(LaunchStarted event, Emitter<LaunchState> emit) async {
    final Either<Failure, bool> done = await _preferences.onboardingDone().run();
    emit(
      done.match(
        (Failure failure) {
          AppLogger.log(tag: 'launch.preferences_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
          return LaunchFailed(failure);
        },
        (bool done) => done ? const LaunchReady() : const LaunchNeedsOnboarding(),
      ),
    );
  }

  // why: the blocks-assemble entrance plays only on the way in from onboarding (FR-ON-5).
  void _onOnboardingFinished(LaunchOnboardingFinished event, Emitter<LaunchState> emit) =>
      emit(const LaunchReady(assemble: true));
}
