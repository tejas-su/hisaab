import 'package:equatable/equatable.dart';

import '../../domain/entities/theme_choice.dart';

/// What changes the app's look (SPEC FR-SE-3).
sealed class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The app opened; read the saved look.
final class ThemeLoadRequested extends ThemeEvent {
  const ThemeLoadRequested();
}

/// The user tapped [choice] under *Look* in Settings.
final class ThemePicked extends ThemeEvent {
  const ThemePicked(this.choice);

  final ThemeChoice choice;

  @override
  List<Object?> get props => <Object?>[choice];
}
