import 'package:equatable/equatable.dart';

import '../../../core/time/pay_rule.dart';

/// What the person did on the income sheet (SPEC FR-SE-1, D137).
sealed class IncomeSheetEvent extends Equatable {
  const IncomeSheetEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The Amount row was tapped: open the keypad, prefilled.
final class IncomeSheetAmountOpened extends IncomeSheetEvent {
  const IncomeSheetAmountOpened();
}

/// Back on a question returns to the slip; on the slip it closes the sheet.
final class IncomeSheetBackPressed extends IncomeSheetEvent {
  const IncomeSheetBackPressed();
}

/// A digit key was tapped.
final class IncomeSheetKeyPressed extends IncomeSheetEvent {
  const IncomeSheetKeyPressed(this.key);

  /// `0`–`9` or `00`.
  final String key;

  @override
  List<Object?> get props => <Object?>[key];
}

/// The backspace key was tapped.
final class IncomeSheetBackspacePressed extends IncomeSheetEvent {
  const IncomeSheetBackspacePressed();
}

/// The backspace key was held: clear the amount.
final class IncomeSheetCleared extends IncomeSheetEvent {
  const IncomeSheetCleared();
}

/// *Save* on the amount question.
final class IncomeSheetAmountSaved extends IncomeSheetEvent {
  const IncomeSheetAmountSaved();
}

/// The "Changed." note has shown long enough.
final class IncomeSheetSavedNoteExpired extends IncomeSheetEvent {
  const IncomeSheetSavedNoteExpired();
}

/// *Change this month too*: give the pay already posted the new amount.
final class IncomeSheetThisMonthChanged extends IncomeSheetEvent {
  const IncomeSheetThisMonthChanged();
}

/// *Undo* after *Change this month too*.
final class IncomeSheetThisMonthUndone extends IncomeSheetEvent {
  const IncomeSheetThisMonthUndone();
}

/// The *When it comes* row was tapped: open the choices on the current rule.
final class IncomeSheetWhenOpened extends IncomeSheetEvent {
  const IncomeSheetWhenOpened();
}

/// *Pick a date* was tapped: open the 1–31 grid.
final class IncomeSheetDayGridOpened extends IncomeSheetEvent {
  const IncomeSheetDayGridOpened();
}

/// *Every week* was tapped: open the weekdays.
final class IncomeSheetWeekdayGridOpened extends IncomeSheetEvent {
  const IncomeSheetWeekdayGridOpened();
}

/// A choice, a day or a weekday was picked: preview it before saving.
final class IncomeSheetPayRuleChosen extends IncomeSheetEvent {
  const IncomeSheetPayRuleChosen(this.rule);

  final PayRule rule;

  @override
  List<Object?> get props => <Object?>[rule];
}

/// *Save* on the choices: change when the money comes (BR-1a, D140).
final class IncomeSheetPayRuleSaved extends IncomeSheetEvent {
  const IncomeSheetPayRuleSaved();
}
