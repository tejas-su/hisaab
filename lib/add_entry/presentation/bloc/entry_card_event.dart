import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/time/calendar_date.dart';
import '../../../ledger/ledger.dart';
import 'entry_card_state.dart';

/// What happens to the entry card (SPEC FR-AD-8).
sealed class EntryCardEvent extends Equatable {
  const EntryCardEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// The events that open, write or close; they run one at a time, in order (see [EntryCardBloc]).
sealed class EntryCardWrite extends EntryCardEvent {
  const EntryCardWrite();
}

/// A row was tapped: open [entry] as a card, with [part] unfolded when the tap asked for one.
/// [categories] are every category; [summary] gives the allowed dates and Home's figure.
final class EntryCardOpened extends EntryCardWrite {
  const EntryCardOpened(
    this.entry, {
    required this.categories,
    this.summary = const Option<CycleSummary>.none(),
    this.part = const Option<CardPart>.none(),
  });

  final Entry entry;
  final List<Category> categories;
  final Option<CycleSummary> summary;
  final Option<CardPart> part;

  @override
  List<Object?> get props => <Object?>[entry, categories, summary, part];
}

/// A part's button in the card was tapped: unfold it, or fold it when it is open (AC-2).
final class EntryCardPartTapped extends EntryCardEvent {
  const EntryCardPartTapped(this.part);

  final CardPart part;

  @override
  List<Object?> get props => <Object?>[part];
}

/// A digit key, `0`–`9` or `00` (AC-3).
final class EntryCardKeyPressed extends EntryCardEvent {
  const EntryCardKeyPressed(this.key);

  final String key;

  @override
  List<Object?> get props => <Object?>[key];
}

/// ⌫ on the card's keypad.
final class EntryCardBackspacePressed extends EntryCardEvent {
  const EntryCardBackspacePressed();
}

/// A long press on ⌫: the typed amount goes to ₹0.
final class EntryCardCleared extends EntryCardEvent {
  const EntryCardCleared();
}

/// The keypad's *Keep* / *Change to* key: keep the typed amount and fold the keypad.
final class EntryCardAmountKept extends EntryCardEvent {
  const EntryCardAmountKept();
}

/// A tile was tapped (AC-4).
final class EntryCardCategoryPicked extends EntryCardEvent {
  const EntryCardCategoryPicked(this.categoryId);

  final int categoryId;

  @override
  List<Object?> get props => <Object?>[categoryId];
}

/// A day pill or the date picker chose [date] (AC-6).
final class EntryCardDayPicked extends EntryCardEvent {
  const EntryCardDayPicked(this.date);

  final CalendarDate date;

  @override
  List<Object?> get props => <Object?>[date];
}

/// The note field changed (AC-7).
final class EntryCardNoteChanged extends EntryCardEvent {
  const EntryCardNoteChanged(this.note);

  final String note;

  @override
  List<Object?> get props => <Object?>[note];
}

/// The new category's name field changed (AC-5).
final class EntryCardNameChanged extends EntryCardEvent {
  const EntryCardNameChanged(this.name);

  final String name;

  @override
  List<Object?> get props => <Object?>[name];
}

/// An icon was picked for the new category; its name's own icon means "follow the name" again.
final class EntryCardIconPicked extends EntryCardEvent {
  const EntryCardIconPicked(this.iconKey);

  final String iconKey;

  @override
  List<Object?> get props => <Object?>[iconKey];
}

/// *Move to {name}*: find or make the category, and move the entry into it (AC-5). [labels] are
/// the built-in categories' names in the app's language, so a typed "Food" finds Food.
final class EntryCardNewCategorySaved extends EntryCardWrite {
  const EntryCardNewCategorySaved(this.labels);

  final Map<int, String> labels;

  @override
  List<Object?> get props => <Object?>[labels];
}

/// *Done*, Back or a tap outside: close, writing once if anything changed (AC-9).
final class EntryCardDone extends EntryCardWrite {
  const EntryCardDone();
}

/// Delete in the card: close without writing and hand the entry to the page (AC-10).
final class EntryCardDeleteRequested extends EntryCardWrite {
  const EntryCardDeleteRequested();
}

/// Undo on the edit's snackbar: write [edit]'s original back (SPEC BR-10).
final class EntryCardUndoRequested extends EntryCardWrite {
  const EntryCardUndoRequested(this.edit);

  final EntryEdit edit;

  @override
  List<Object?> get props => <Object?>[edit];
}
