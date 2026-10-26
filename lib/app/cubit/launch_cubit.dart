import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../core/errors/failure.dart';
import '../../core/logging/app_logger.dart';
import '../../settings/settings.dart';
import 'launch_state.dart';

/// Decides the root screen: onboarding or the app. Driven by [start] at launch and
/// [onboardingFinished] from the onboarding page.
class LaunchCubit extends Cubit<LaunchState> {
  LaunchCubit({required this._preferences}) : super(const LaunchLoading());

  final AppPreferencesRepository _preferences;

  /// Reads whether onboarding was finished and shows the matching screen.
  Future<void> start() async {
    final Either<Failure, bool> done = await _preferences.onboardingDone().run();
    if (isClosed) {
      return;
    }
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

  /// Moves to the app after onboarding, with the blocks-assemble entrance.
  void onboardingFinished() => emit(const LaunchReady(assemble: true));
}
