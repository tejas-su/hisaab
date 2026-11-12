import 'package:equatable/equatable.dart';

/// What happens to the *Your usual* row of one category's sheet (SPEC FR-SE-2 AC-6).
sealed class UsualRowEvent extends Equatable {
  const UsualRowEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The sheet opened on its summary: work out whether the category has a habit to show.
final class UsualRowLoadRequested extends UsualRowEvent {
  /// Asks for the category's habit.
  const UsualRowLoadRequested();
}

/// The user tapped *Forget* on the row.
final class UsualRowForgetRequested extends UsualRowEvent {
  /// Asks to forget the habit shown.
  const UsualRowForgetRequested();
}

/// The user tapped *Undo* on "Forgotten".
final class UsualRowForgetUndone extends UsualRowEvent {
  /// Asks to put back what *Forget* replaced.
  const UsualRowForgetUndone();
}
