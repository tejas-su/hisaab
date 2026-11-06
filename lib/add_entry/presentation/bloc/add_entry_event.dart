import 'package:equatable/equatable.dart';

import '../../../core/time/calendar_date.dart';
import '../../../ledger/ledger.dart';

/// What the user does in the Add tray.
sealed class AddEntryEvent extends Equatable {
  const AddEntryEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The user switched between *Spent* and *Got*.
final class AddEntryKindChanged extends AddEntryEvent {
  const AddEntryKindChanged(this.kind);

  final EntryKind kind;

  @override
  List<Object?> get props => <Object?>[kind];
}

/// The user pressed keypad [key] (`0`–`9`, `00`).
final class AddEntryKeyPressed extends AddEntryEvent {
  const AddEntryKeyPressed(this.key);

  final String key;

  @override
  List<Object?> get props => <Object?>[key];
}

/// The user tapped a quick chip worth [rupees] (FR-AD-1).
final class AddEntryQuickAdded extends AddEntryEvent {
  const AddEntryQuickAdded(this.rupees);

  final int rupees;

  @override
  List<Object?> get props => <Object?>[rupees];
}

/// The user pressed ⌫.
final class AddEntryBackspacePressed extends AddEntryEvent {
  const AddEntryBackspacePressed();
}

/// The user long-pressed ⌫ to empty the amount.
final class AddEntryCleared extends AddEntryEvent {
  const AddEntryCleared();
}

/// The user tapped Next on step 1.
final class AddEntryNextPressed extends AddEntryEvent {
  const AddEntryNextPressed();
}

/// The user pressed back on step 2.
final class AddEntryBackPressed extends AddEntryEvent {
  const AddEntryBackPressed();
}

/// The user picked [date] on the date chip.
final class AddEntryDateChanged extends AddEntryEvent {
  const AddEntryDateChanged(this.date);

  final CalendarDate date;

  @override
  List<Object?> get props => <Object?>[date];
}

/// The user typed [note]; it is trimmed when saved.
final class AddEntryNoteChanged extends AddEntryEvent {
  const AddEntryNoteChanged(this.note);

  final String note;

  @override
  List<Object?> get props => <Object?>[note];
}

/// The user tapped the tile for [categoryId]; the tap is the save (FR-AD-5).
final class AddEntryCategoryPicked extends AddEntryEvent {
  const AddEntryCategoryPicked(this.categoryId);

  final int categoryId;

  @override
  List<Object?> get props => <Object?>[categoryId];
}

/// The user tapped Delete on the entry being edited.
final class AddEntryDeleteRequested extends AddEntryEvent {
  const AddEntryDeleteRequested();
}

/// The user tapped the *New* tile to make a category of their own (FR-AD-9).
final class AddEntryNewCategoryOpened extends AddEntryEvent {
  const AddEntryNewCategoryOpened();
}

/// The user typed [name] for the new category, or tapped a name chip.
final class AddEntryNewCategoryNameChanged extends AddEntryEvent {
  const AddEntryNewCategoryNameChanged(this.name);

  final String name;

  @override
  List<Object?> get props => <Object?>[name];
}

/// The user tapped *Change* to pick the new category's icon.
final class AddEntryIconStepOpened extends AddEntryEvent {
  const AddEntryIconStepOpened();
}

/// The user picked the icon with app-owned [iconKey] on the icon step.
final class AddEntryIconPicked extends AddEntryEvent {
  const AddEntryIconPicked(this.iconKey);

  final String iconKey;

  @override
  List<Object?> get props => <Object?>[iconKey];
}

/// The user tapped *Save in {name}*: file the entry under the typed name (FR-AD-9 AC-4).
///
/// [labels] holds each category's shown name by id, so a typed name that matches a built-in
/// category (whose name is localised) saves there.
final class AddEntryNewCategorySaved extends AddEntryEvent {
  const AddEntryNewCategorySaved(this.labels);

  final Map<int, String> labels;

  @override
  List<Object?> get props => <Object?>[labels];
}
