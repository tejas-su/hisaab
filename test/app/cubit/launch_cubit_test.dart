import 'package:expense_tracker/app/cubit/launch_cubit.dart';
import 'package:expense_tracker/app/cubit/launch_state.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fakes/fake_app_preferences_repository.dart';

void main() {
  group('LaunchCubit', () {
    test('starts loading', () {
      final LaunchCubit cubit = LaunchCubit(preferences: FakeAppPreferencesRepository());
      addTearDown(cubit.close);
      expect(cubit.state, const LaunchLoading());
    });

    test('a fresh install needs onboarding (FR-ON-1)', () async {
      final LaunchCubit cubit = LaunchCubit(preferences: FakeAppPreferencesRepository());
      addTearDown(cubit.close);
      await cubit.start();
      expect(cubit.state, const LaunchNeedsOnboarding());
    });

    test('a finished onboarding goes straight to the app without the entrance', () async {
      final LaunchCubit cubit = LaunchCubit(preferences: FakeAppPreferencesRepository(done: true));
      addTearDown(cubit.close);
      await cubit.start();
      expect(cubit.state, const LaunchReady());
    });

    test('a read failure shows the startup failure', () async {
      final FakeAppPreferencesRepository preferences = FakeAppPreferencesRepository()..failure = DatabaseFailure('locked');
      final LaunchCubit cubit = LaunchCubit(preferences: preferences);
      addTearDown(cubit.close);
      await cubit.start();
      expect(cubit.state, isA<LaunchFailed>());
    });

    test('finishing onboarding opens the app with the blocks-assemble entrance', () {
      final LaunchCubit cubit = LaunchCubit(preferences: FakeAppPreferencesRepository());
      addTearDown(cubit.close);
      cubit.onboardingFinished();
      expect(cubit.state, const LaunchReady(assemble: true));
    });

    test('closing before the read finishes emits nothing', () async {
      final LaunchCubit cubit = LaunchCubit(preferences: FakeAppPreferencesRepository());
      final Future<void> started = cubit.start();
      await cubit.close();
      await expectLater(started, completes);
    });
  });
}
