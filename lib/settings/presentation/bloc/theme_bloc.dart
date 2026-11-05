import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../domain/entities/theme_choice.dart';
import '../../domain/repository/app_preferences_repository.dart';
import 'theme_event.dart';
import 'theme_state.dart';

/// Owns the app's look (SPEC FR-SE-3), above `MaterialApp`. [ThemeLoadRequested] reads it at
/// launch; [ThemePicked] from Settings applies it at once and saves it.
class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc({required this._preferences}) : super(const ThemeState(ThemeChoice.matchPhone)) {
    // why: a load must not land after a pick and undo it, so both share one queue in order.
    on<ThemeEvent>(
      (ThemeEvent event, Emitter<ThemeState> emit) => switch (event) {
        ThemeLoadRequested() => _onLoadRequested(emit),
        ThemePicked(:final ThemeChoice choice) => _onPicked(choice, emit),
      },
      transformer: sequential(),
    );
  }

  final AppPreferencesRepository _preferences;

  Future<void> _onLoadRequested(Emitter<ThemeState> emit) async {
    final Either<Failure, ThemeChoice> loaded = await _preferences.themeChoice().run();
    loaded.match(
      (Failure failure) => _logFailure('theme.load_failed', failure),
      (ThemeChoice choice) => emit(ThemeState(choice)),
    );
  }

  Future<void> _onPicked(ThemeChoice choice, Emitter<ThemeState> emit) async {
    // why: the app changes look on the tap itself; the write follows.
    emit(ThemeState(choice));
    final Either<Failure, Unit> saved = await _preferences.saveThemeChoice(choice).run();
    saved.match((Failure failure) => _logFailure('theme.save_failed', failure), (Unit _) {});
  }

  static void _logFailure(String tag, Failure failure) =>
      AppLogger.log(tag: tag, data: <String, Object?>{'type': failure.runtimeType.toString()});
}
