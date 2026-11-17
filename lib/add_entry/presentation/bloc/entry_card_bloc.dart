import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/money/amount_input.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../ledger/ledger.dart';
import 'add_entry_bloc.dart';
import 'entry_card_event.dart';
import 'entry_card_state.dart';

/// Owns the entry card (SPEC FR-AD-8): which entry is open, its values as they are now, the part
/// unfolded, and the one write when it closes.
///
/// One lives above a list of entries (Home, Every entry); a row tap adds [EntryCardOpened]. Nothing
/// is written until [EntryCardDone]; the page offers Undo from [EntryCardClosed.edit] and deletes
/// what [EntryCardClosed.deleted] hands it.
class EntryCardBloc extends Bloc<EntryCardEvent, EntryCardState> {
  EntryCardBloc({required this._saveEntry, required this._addOwnCategory, required this._haptics, required this._clock})
      : super(const EntryCardClosed()) {
    // why: a tap outside the card closes it, and the same tap may open another row: the close must
    // write before the open runs, and a second Done finds the card closed, so nothing writes twice.
    on<EntryCardWrite>(
      (EntryCardWrite event, Emitter<EntryCardState> emit) => switch (event) {
        EntryCardOpened() => _onOpened(event, emit),
        EntryCardNewCategorySaved() => _onNewCategorySaved(event, emit),
        EntryCardDone() => _close(emit),
        EntryCardDeleteRequested() => _onDeleteRequested(emit),
        EntryCardUndoRequested() => _onUndoRequested(event, emit),
      },
      transformer: sequential(),
    );
    on<EntryCardPartTapped>(_onPartTapped);
    on<EntryCardKeyPressed>(_onKeyPressed);
    on<EntryCardBackspacePressed>(
      (EntryCardBackspacePressed event, Emitter<EntryCardState> emit) =>
          _type(emit, (EntryCardForm form) => Option<int>.of(AmountInput.backspace(form.shownRupees))),
    );
    on<EntryCardCleared>((EntryCardCleared event, Emitter<EntryCardState> emit) => _type(emit, (EntryCardForm _) => const Option<int>.of(0)));
    on<EntryCardAmountKept>(_onAmountKept);
    on<EntryCardCategoryPicked>(
      (EntryCardCategoryPicked event, Emitter<EntryCardState> emit) =>
          _pick(emit, (EntryCardForm form) => form.copyWith(categoryId: event.categoryId)),
    );
    on<EntryCardDayPicked>(_onDayPicked);
    on<EntryCardNoteChanged>(
      (EntryCardNoteChanged event, Emitter<EntryCardState> emit) => _update(emit, (EntryCardForm form) => form.copyWith(note: event.note)),
    );
    on<EntryCardNameChanged>(
      (EntryCardNameChanged event, Emitter<EntryCardState> emit) => _update(emit, (EntryCardForm form) => form.copyWith(draftName: event.name)),
    );
    on<EntryCardIconPicked>(_onIconPicked);
  }

  final SaveEntry _saveEntry;
  final AddOwnCategory _addOwnCategory;
  final Haptics _haptics;
  final Clock _clock;

  /// Opens [EntryCardOpened.entry]; a card already open closes first, writing its change (AC-1).
  Future<void> _onOpened(EntryCardOpened event, Emitter<EntryCardState> emit) async {
    if (state is EntryCardOpen) {
      await _close(emit);
    }
    final CalendarDate today = _clock.today();
    final Entry entry = event.entry;
    unawaited(_haptics.tick());
    emit(
      EntryCardOpen(
        EntryCardForm(
          original: entry,
          rupees: entry.amount.floorMajor,
          categoryId: entry.categoryId,
          date: entry.date,
          note: entry.note ?? '',
          today: today,
          earliestDate: event.summary.match(
            () => today.addDays(-AddEntryBloc.fallbackHistoryDays),
            (CycleSummary summary) => summary.earliestEntryDate,
          ),
          categories: event.categories,
          part: event.part,
          safeToday: event.summary.map((CycleSummary summary) => summary.safeToday),
        ),
      ),
    );
  }

  /// Unfolds [EntryCardPartTapped.part], or folds it when open; a typed amount is kept (AC-8).
  void _onPartTapped(EntryCardPartTapped event, Emitter<EntryCardState> emit) => _update(emit, (EntryCardForm form) {
        final EntryCardForm kept = _keepTyped(form);
        final bool open = form.part == Option<CardPart>.of(event.part);
        return kept.copyWith(part: open ? const Option<CardPart>.none() : Option<CardPart>.of(event.part));
      });

  /// The first digit replaces the old amount; later ones append, up to the cap (AC-3, FR-AD-2).
  void _onKeyPressed(EntryCardKeyPressed event, Emitter<EntryCardState> emit) => _type(
        emit,
        (EntryCardForm form) => form.typed.match(
          () => Option<int>.of(int.parse(event.key)),
          (int typed) => AmountInput.append(typed, event.key),
        ),
      );

  /// Keeps a typed amount above ₹0 and folds the keypad; ₹0 is refused (AC-3).
  void _onAmountKept(EntryCardAmountKept event, Emitter<EntryCardState> emit) {
    final EntryCardForm? form = _openForm;
    if (form == null || form.shownRupees == 0) {
      return;
    }
    unawaited(_haptics.tick());
    _update(emit, (EntryCardForm form) => _keepTyped(form).copyWith(part: const Option<CardPart>.none()));
  }

  /// Moves the entry to a day between the earliest allowed and today, and folds the pills (AC-6).
  void _onDayPicked(EntryCardDayPicked event, Emitter<EntryCardState> emit) => _pick(emit, (EntryCardForm form) {
        final CalendarDate notFuture = event.date.isAfter(form.today) ? form.today : event.date;
        return form.copyWith(date: notFuture.isBefore(form.earliestDate) ? form.earliestDate : notFuture);
      });

  /// Sets the new category's icon; the name's own icon follows the name again (FR-AD-9 AC-3).
  void _onIconPicked(EntryCardIconPicked event, Emitter<EntryCardState> emit) => _update(
        emit,
        (EntryCardForm form) => form.copyWith(
          draftIcon: event.iconKey == CategoryIcon.forName(form.draftName) ? const Option<String>.none() : Option<String>.of(event.iconKey),
        ),
      );

  /// Finds or makes the named category and moves the entry into it; nothing else is written (AC-5).
  Future<void> _onNewCategorySaved(EntryCardNewCategorySaved event, Emitter<EntryCardState> emit) async {
    final EntryCardForm? form = _openForm;
    if (form == null || form.draftName.trim().isEmpty) {
      return;
    }
    final Either<Failure, Category> found =
        await _addOwnCategory(NewCategory(name: form.draftName, iconKey: form.draftIconKey, labels: event.labels)).run();
    found.match(
      (Failure failure) => _fail(emit, form, failure),
      (Category category) {
        unawaited(_haptics.tick());
        emit(EntryCardOpen(_movedInto(form, category)));
      },
    );
  }

  static EntryCardForm _movedInto(EntryCardForm form, Category category) => form.copyWith(
        categoryId: category.id,
        categories: <Category>[...form.categories.where((Category c) => c.id != category.id), category],
        part: const Option<CardPart>.none(),
        draftName: '',
        draftIcon: const Option<String>.none(),
      );

  /// Closes without writing and hands the entry to the page, which deletes it with Undo (AC-10).
  Future<void> _onDeleteRequested(Emitter<EntryCardState> emit) async {
    final EntryCardForm? form = _openForm;
    if (form != null) {
      emit(EntryCardClosed(deleted: Option<Entry>.of(form.original)));
    }
  }

  /// Writes the edit's original back, `created_at` and all (SPEC BR-10).
  Future<void> _onUndoRequested(EntryCardUndoRequested event, Emitter<EntryCardState> emit) async {
    final Entry original = event.edit.original;
    final Either<Failure, Entry> restored = await _saveEntry(SaveEntryParams(original.draft, replacing: Option<int>.of(original.id))).run();
    restored.match(
      (Failure failure) => AppLogger.log(tag: 'entry_card.undo_failed', data: <String, Object?>{'type': failure.runtimeType.toString()}),
      (Entry _) => unawaited(_haptics.tick()),
    );
    if (state is EntryCardClosed) {
      emit(const EntryCardClosed());
    }
  }

  /// Writes the card once if anything changed, then closes; a failure keeps it open (AC-9).
  Future<void> _close(Emitter<EntryCardState> emit) async {
    final EntryCardForm? open = _openForm;
    if (open == null) {
      return;
    }
    final EntryCardForm form = _keepTyped(open);
    final List<CardChange> changes = form.changes;
    if (changes.isEmpty) {
      emit(const EntryCardClosed());
      return;
    }
    emit(EntryCardSaving(form));
    final Either<Failure, Entry> saved =
        await _saveEntry(SaveEntryParams(form.draft, replacing: Option<int>.of(form.original.id))).run();
    saved.match(
      (Failure failure) => _fail(emit, form, failure),
      (Entry entry) {
        unawaited(_haptics.success());
        emit(EntryCardClosed(edit: Option<EntryEdit>.of(EntryEdit(original: form.original, saved: entry, changes: changes, categories: form.categories, today: form.today))));
      },
    );
  }

  void _fail(Emitter<EntryCardState> emit, EntryCardForm form, Failure failure) {
    AppLogger.log(tag: 'entry_card.save_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
    unawaited(_haptics.reject());
    emit(EntryCardOpen(form, failed: true));
  }

  /// Applies a pick (a tile, a day) and folds its part.
  void _pick(Emitter<EntryCardState> emit, EntryCardForm Function(EntryCardForm form) change) {
    unawaited(_haptics.tick());
    _update(emit, (EntryCardForm form) => change(_keepTyped(form)).copyWith(part: const Option<CardPart>.none()));
  }

  /// Changes the typed amount; [None] from [edit] is a refused key (the 9-digit cap).
  void _type(Emitter<EntryCardState> emit, Option<int> Function(EntryCardForm form) edit) {
    final EntryCardState current = state;
    if (current is! EntryCardOpen) {
      return;
    }
    edit(current.form).match(
      () {
        unawaited(_haptics.reject());
        emit(EntryCardOpen(current.form, rejections: current.rejections + 1));
      },
      (int rupees) {
        unawaited(_haptics.tick());
        emit(EntryCardOpen(current.form.copyWith(typed: Option<int>.of(rupees)), rejections: current.rejections));
      },
    );
  }

  void _update(Emitter<EntryCardState> emit, EntryCardForm Function(EntryCardForm form) change) {
    final EntryCardState current = state;
    if (current is EntryCardOpen) {
      emit(EntryCardOpen(change(current.form), rejections: current.rejections));
    }
  }

  // why: a typed ₹0 is not an amount; leaving the keypad then keeps the amount it had.
  static EntryCardForm _keepTyped(EntryCardForm form) =>
      form.copyWith(rupees: form.typed.filter((int r) => r > 0).getOrElse(() => form.rupees), typed: const Option<int>.none());

  EntryCardForm? get _openForm => switch (state) {
        EntryCardOpen(:final EntryCardForm form) => form,
        EntryCardClosed() || EntryCardSaving() => null,
      };
}
