import 'package:equatable/equatable.dart';

import '../../domain/entities/theme_choice.dart';

/// The look the whole app is drawn in right now (SPEC FR-SE-3).
final class ThemeState extends Equatable {
  const ThemeState(this.choice);

  final ThemeChoice choice;

  @override
  List<Object?> get props => <Object?>[choice];
}
