import 'package:bloc_concurrency/bloc_concurrency.dart';
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
    // why: the newest replacement wins, so an older read can't land a stale root screen.
    on<LaunchDataReplaced>(_onDataReplaced, transformer: restartable());
  }

  final AppPreferencesRepository _preferences;

  /// How many times the data was replaced; it keys the rebuilt root screen.
  int _generation = 0;

  Future<void> _onStarted(LaunchStarted event, Emitter<LaunchState> emit) => _read(emit);

  Future<void> _onDataReplaced(LaunchDataReplaced event, Emitter<LaunchState> emit) {
    _generation++;
    emit(const LaunchLoading());
    return _read(emit);
  }

  Future<void> _read(Emitter<LaunchState> emit) async {
    final Either<Failure, bool> done = await _preferences.onboardingDone().run();
    emit(
      done.match(
        (Failure failure) {
          AppLogger.log(tag: 'launch.preferences_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
          return LaunchFailed(failure);
        },
        (bool done) => done ? LaunchReady(generation: _generation) : const LaunchNeedsOnboarding(),
      ),
    );
  }

  // why: the blocks-assemble entrance plays only on the way in from onboarding (FR-ON-5).
  void _onOnboardingFinished(LaunchOnboardingFinished event, Emitter<LaunchState> emit) =>
      emit(const LaunchReady(assemble: true));
}
