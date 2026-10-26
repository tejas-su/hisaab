import 'package:expense_tracker/app/bloc/launch_bloc.dart';
import 'package:expense_tracker/app/bloc/launch_event.dart';
import 'package:expense_tracker/app/bloc/launch_state.dart';
import 'package:expense_tracker/core/errors/failure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/bloc_dispatch.dart';
import '../../helpers/fakes/fake_app_preferences_repository.dart';

void main() {
  group('LaunchBloc', () {
    test('starts loading', () {
      final LaunchBloc bloc = LaunchBloc(preferences: FakeAppPreferencesRepository());
      addTearDown(bloc.close);
      expect(bloc.state, const LaunchLoading());
    });

    test('a fresh install needs onboarding (FR-ON-1)', () async {
      final LaunchBloc bloc = LaunchBloc(preferences: FakeAppPreferencesRepository());
      addTearDown(bloc.close);
      await bloc.dispatch(const LaunchStarted());
      expect(bloc.state, const LaunchNeedsOnboarding());
    });

    test('a finished onboarding goes straight to the app without the entrance', () async {
      final LaunchBloc bloc = LaunchBloc(preferences: FakeAppPreferencesRepository(done: true));
      addTearDown(bloc.close);
      await bloc.dispatch(const LaunchStarted());
      expect(bloc.state, const LaunchReady());
    });

    test('a read failure shows the startup failure', () async {
      final FakeAppPreferencesRepository preferences = FakeAppPreferencesRepository()..failure = DatabaseFailure('locked');
      final LaunchBloc bloc = LaunchBloc(preferences: preferences);
      addTearDown(bloc.close);
      await bloc.dispatch(const LaunchStarted());
      expect(bloc.state, isA<LaunchFailed>());
    });

    test('finishing onboarding opens the app with the blocks-assemble entrance', () async {
      final LaunchBloc bloc = LaunchBloc(preferences: FakeAppPreferencesRepository());
      addTearDown(bloc.close);
      await bloc.dispatch(const LaunchOnboardingFinished());
      expect(bloc.state, const LaunchReady(assemble: true));
    });

    test('closing before the read finishes does not throw', () async {
      final LaunchBloc bloc = LaunchBloc(preferences: FakeAppPreferencesRepository())..add(const LaunchStarted());
      await expectLater(bloc.close(), completes);
    });

    test('events compare by type', () {
      expect(const LaunchStarted(), const LaunchStarted());
      expect(const LaunchOnboardingFinished().props, isEmpty);
    });
  });
}
