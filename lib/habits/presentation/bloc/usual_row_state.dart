import 'package:equatable/equatable.dart';

import '../../domain/entities/forgotten_usual.dart';
import '../../domain/entities/usual_habit.dart';

/// What the *Your usual* row of a category's sheet shows (SPEC FR-SE-2 AC-6).
sealed class UsualRowState extends Equatable {
  const UsualRowState();
}

/// The category has no Regular habit, or it isn't known yet: no row is built.
final class UsualRowEmpty extends UsualRowState {
  /// The state before the first load, and whenever there is nothing to show.
  const UsualRowEmpty();

  @override
  List<Object?> get props => <Object?>[];
}

/// The category has a Regular habit: the row shows it with *Forget*.
final class UsualRowShown extends UsualRowState {
  /// Shows [habit].
  const UsualRowShown(this.habit);

  /// The habit of today's day type, or of the other when today's has none.
  final UsualHabit habit;

  @override
  List<Object?> get props => <Object?>[habit];
}

/// *Forget* was just tapped: the row is gone and the sheet offers "Forgotten" with *Undo*.
final class UsualRowForgotten extends UsualRowState {
  /// Holds what [forgotten] replaced, for Undo.
  const UsualRowForgotten(this.forgotten);

  /// The category and the state Undo puts back.
  final ForgottenUsual forgotten;

  @override
  List<Object?> get props => <Object?>[forgotten];
}
