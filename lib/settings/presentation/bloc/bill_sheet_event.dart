import 'package:equatable/equatable.dart';

import '../../../ledger/ledger.dart';
import 'bill_sheet_state.dart';

/// What the user does on the bill sheet (SPEC FR-SE-1, D118).
sealed class BillSheetEvent extends Equatable {
  const BillSheetEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The bill's stamp and next date should be loaded, when the sheet opens.
final class BillSheetStatusRequested extends BillSheetEvent {
  const BillSheetStatusRequested();
}

/// The user tapped the row for [answer], opening its question.
final class BillSheetAnswerOpened extends BillSheetEvent {
  const BillSheetAnswerOpened(this.answer);

  final BillAnswer answer;

  @override
  List<Object?> get props => <Object?>[answer];
}

/// The user pressed Back: from a question to the bill, or from the bill to close it.
final class BillSheetBackPressed extends BillSheetEvent {
  const BillSheetBackPressed();
}

/// The user pressed keypad [key] (`0`–`9`, `00`) on the amount question.
final class BillSheetKeyPressed extends BillSheetEvent {
  const BillSheetKeyPressed(this.key);

  final String key;

  @override
  List<Object?> get props => <Object?>[key];
}

/// The user pressed ⌫ on the amount question.
final class BillSheetBackspacePressed extends BillSheetEvent {
  const BillSheetBackspacePressed();
}

/// The user long-pressed ⌫ to empty the amount.
final class BillSheetCleared extends BillSheetEvent {
  const BillSheetCleared();
}

/// The user tapped Save on the amount question.
final class BillSheetAmountSaved extends BillSheetEvent {
  const BillSheetAmountSaved();
}

/// The user tapped [day] of the month; this saves it.
final class BillSheetDayChosen extends BillSheetEvent {
  const BillSheetDayChosen(this.day);

  final int day;

  @override
  List<Object?> get props => <Object?>[day];
}

/// The user typed [name] in the name question.
final class BillSheetNameChanged extends BillSheetEvent {
  const BillSheetNameChanged(this.name);

  final String name;

  @override
  List<Object?> get props => <Object?>[name];
}

/// The user tapped Save on the name question.
final class BillSheetNameSaved extends BillSheetEvent {
  const BillSheetNameSaved();
}

/// The user tapped [icon] in the icon grid; this saves it.
final class BillSheetIconChosen extends BillSheetEvent {
  const BillSheetIconChosen(this.icon);

  final BillIcon icon;

  @override
  List<Object?> get props => <Object?>[icon];
}

/// The user tapped *Delete bill*.
final class BillSheetDeleteRequested extends BillSheetEvent {
  const BillSheetDeleteRequested();
}

/// The "Saved." note has been shown long enough.
final class BillSheetSavedNoteExpired extends BillSheetEvent {
  const BillSheetSavedNoteExpired();
}
