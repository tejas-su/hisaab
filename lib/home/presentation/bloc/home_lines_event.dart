import 'package:equatable/equatable.dart';

import '../../../habits/habits.dart';
import '../../../ledger/ledger.dart';

/// What Home knows at the moment the missed-log line is decided (SPEC FR-HO-3, D170).
final class HomeLinesFacts extends Equatable {
  /// Creates the facts of one evaluation at [now].
  const HomeLinesFacts({
    required this.index,
    required this.categories,
    required this.now,
    this.noIncome = false,
    this.overState = false,
    this.billLineShowing = false,
    this.installDue = false,
  });

  /// The habit index read at that instant; null while the habits had not loaded (E106).
  final HabitIndex? index;

  /// The categories Home shows.
  final List<Category> categories;

  /// The time of the evaluation.
  final DateTime now;

  /// Home is in *No income* (E107).
  final bool noIncome;

  /// Home is in an over state (E107).
  final bool overState;

  /// A waiting or due-soon bill holds the nudge slot (B4).
  final bool billLineShowing;

  /// Whether the one-time install line is due: a mid-cycle install on its first visits, not yet seen
  /// and not used up by a fix (FR-HO-3).
  final bool installDue;

  @override
  List<Object?> get props => <Object?>[index, categories, now, noIncome, overState, billLineShowing, installDue];
}

/// What happens to the missed-log line. Only [HomeLinesEvaluated] can make a line appear; every
/// other event makes it stay or leave (D170).
sealed class HomeLinesEvent extends Equatable {
  const HomeLinesEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// An evaluation point: a cold start or a resume. The next evaluation is allowed to decide.
final class HomeLinesPointReached extends HomeLinesEvent {
  const HomeLinesPointReached();
}

/// Home was ready at the latched point; [facts] decide whether a line is asked.
final class HomeLinesEvaluated extends HomeLinesEvent {
  const HomeLinesEvaluated(this.facts);

  final HomeLinesFacts facts;

  @override
  List<Object?> get props => <Object?>[facts];
}

/// The line was on screen with Home in view and nothing over it: write `asked_on` (AC-4).
final class HomeLinesShown extends HomeLinesEvent {
  const HomeLinesShown();
}

/// The user tapped the line.
final class HomeLinesTapped extends HomeLinesEvent {
  const HomeLinesTapped();
}

/// The tray the line opened has fully closed, saved or not; the line goes (AC-3).
final class HomeLinesTrayClosed extends HomeLinesEvent {
  const HomeLinesTrayClosed();
}

/// An entry dated today exists in category [categoryId], by any door.
final class HomeLinesEntryLogged extends HomeLinesEvent {
  const HomeLinesEntryLogged(this.categoryId);

  final int categoryId;

  @override
  List<Object?> get props => <Object?>[categoryId];
}

/// The gate of category [categoryId] closed: it went quiet, rested or was forgotten.
final class HomeLinesGateClosed extends HomeLinesEvent {
  const HomeLinesGateClosed(this.categoryId);

  final int categoryId;

  @override
  List<Object?> get props => <Object?>[categoryId];
}

/// A bill line took the nudge slot; the lower line goes and does not come back (E108).
final class HomeLinesSlotTaken extends HomeLinesEvent {
  const HomeLinesSlotTaken();
}

/// Midnight passed; the line and any latched point go.
final class HomeLinesMidnight extends HomeLinesEvent {
  const HomeLinesMidnight();
}

/// The install line is on screen with Home in view and nothing over it: mark it seen, once (FR-HO-3).
final class HomeLinesInstallShown extends HomeLinesEvent {
  const HomeLinesInstallShown();
}

/// The user tapped the install line; it opens the *Fix my number* sheet and goes when it closes.
final class HomeLinesInstallTapped extends HomeLinesEvent {
  const HomeLinesInstallTapped();
}

/// A fix was made, which uses the install line up (C11); the line leaves unless it was already seen.
final class HomeLinesInstallConsumed extends HomeLinesEvent {
  const HomeLinesInstallConsumed();
}
