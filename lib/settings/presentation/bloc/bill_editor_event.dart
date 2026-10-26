import 'package:equatable/equatable.dart';

import '../../../ledger/ledger.dart';

/// What the user does on the bill editor.
sealed class BillEditorEvent extends Equatable {
  const BillEditorEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The user typed [label] as the name; it no longer matches a chip.
final class BillEditorRenamed extends BillEditorEvent {
  const BillEditorRenamed(this.label);

  final String label;

  @override
  List<Object?> get props => <Object?>[label];
}

/// The user picked the common bill [kind], shown as [label].
final class BillEditorKindPicked extends BillEditorEvent {
  const BillEditorKindPicked(this.kind, this.label);

  final BillKind kind;
  final String label;

  @override
  List<Object?> get props => <Object?>[kind, label];
}

/// The user tapped Next.
final class BillEditorNextPressed extends BillEditorEvent {
  const BillEditorNextPressed();
}

/// The user pressed keypad [key] (`0`–`9`, `00`).
final class BillEditorKeyPressed extends BillEditorEvent {
  const BillEditorKeyPressed(this.key);

  final String key;

  @override
  List<Object?> get props => <Object?>[key];
}

/// The user pressed ⌫.
final class BillEditorBackspacePressed extends BillEditorEvent {
  const BillEditorBackspacePressed();
}

/// The user long-pressed ⌫ to empty the amount.
final class BillEditorCleared extends BillEditorEvent {
  const BillEditorCleared();
}

/// The user tapped [day] of the month; this saves the bill.
final class BillEditorDayChosen extends BillEditorEvent {
  const BillEditorDayChosen(this.day);

  final int day;

  @override
  List<Object?> get props => <Object?>[day];
}

/// The user pressed back on the amount or day step.
final class BillEditorBackPressed extends BillEditorEvent {
  const BillEditorBackPressed();
}
