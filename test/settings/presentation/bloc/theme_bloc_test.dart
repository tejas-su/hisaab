import 'package:hisaab/core/errors/failure.dart';
import 'package:hisaab/settings/domain/entities/theme_choice.dart';
import 'package:hisaab/settings/presentation/bloc/theme_bloc.dart';
import 'package:hisaab/settings/presentation/bloc/theme_event.dart';
import 'package:hisaab/settings/presentation/bloc/theme_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/bloc_dispatch.dart';
import '../../../helpers/fakes/fake_app_preferences_repository.dart';

void main() {
  group('ThemeBloc (FR-SE-3)', () {
    test('matches the phone before the saved look is read', () {
      final ThemeBloc bloc = ThemeBloc(preferences: FakeAppPreferencesRepository(theme: ThemeChoice.dark));
      addTearDown(bloc.close);
      expect(bloc.state, const ThemeState(ThemeChoice.matchPhone));
    });

    test('loads the saved look', () async {
      final ThemeBloc bloc = ThemeBloc(preferences: FakeAppPreferencesRepository(theme: ThemeChoice.dark));
      addTearDown(bloc.close);
      await bloc.dispatch(const ThemeLoadRequested());
      expect(bloc.state, const ThemeState(ThemeChoice.dark));
    });

    test('a failed read keeps matching the phone', () async {
      final FakeAppPreferencesRepository preferences = FakeAppPreferencesRepository(theme: ThemeChoice.dark)
        ..failure = DatabaseFailure('locked');
      final ThemeBloc bloc = ThemeBloc(preferences: preferences);
      addTearDown(bloc.close);
      await bloc.dispatch(const ThemeLoadRequested());
      expect(bloc.state, const ThemeState(ThemeChoice.matchPhone));
    });

    test('a pick applies at once and is saved', () async {
      final FakeAppPreferencesRepository preferences = FakeAppPreferencesRepository();
      final ThemeBloc bloc = ThemeBloc(preferences: preferences);
      addTearDown(bloc.close);
      await bloc.dispatch(const ThemePicked(ThemeChoice.light));
      expect(bloc.state, const ThemeState(ThemeChoice.light));
      expect(preferences.theme, ThemeChoice.light);
    });

    test('a pick that fails to save still applies for now', () async {
      final FakeAppPreferencesRepository preferences = FakeAppPreferencesRepository()..failure = DatabaseFailure('full');
      final ThemeBloc bloc = ThemeBloc(preferences: preferences);
      addTearDown(bloc.close);
      await bloc.dispatch(const ThemePicked(ThemeChoice.dark));
      expect(bloc.state, const ThemeState(ThemeChoice.dark));
    });
  });

  test('events compare by value', () {
    // why: const instances are identical, so Equatable would never read props.
    // ignore: prefer_const_constructors
    expect(ThemeLoadRequested(), ThemeLoadRequested());
    // ignore: prefer_const_constructors
    expect(ThemePicked(ThemeChoice.dark), ThemePicked(ThemeChoice.dark));
    expect(const ThemePicked(ThemeChoice.dark), isNot(const ThemePicked(ThemeChoice.light)));
  });
}
