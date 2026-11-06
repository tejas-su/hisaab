import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/design/haptics.dart';
import '../../../core/errors/failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/money/amount_input.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../core/time/clock.dart';
import '../../../ledger/ledger.dart';
import 'add_entry_event.dart';
import 'add_entry_state.dart';

/// Owns the Add tray (SPEC FR-AD): the amount, Spent/Got, date, note and the save on a tile tap.
///
/// Created per tray opening by the route, with the Home summary for the preview line and the
/// entry being edited, if any. The page closes the tray on [AddEntryFinished].
class AddEntryBloc extends Bloc<AddEntryEvent, AddEntryState> {
  AddEntryBloc({
    required this._saveEntry,
    required this._deleteEntry,
    required this._addOwnCategory,
    required this._haptics,
    required Clock clock,
    required List<Category> categories,
    Option<CycleSummary> summary = const Option<CycleSummary>.none(),
    Option<Entry> editing = const Option<Entry>.none(),
    EntryKind kind = EntryKind.spent,
  })  : _categories = categories,
        _summary = summary,
        super(AddEntryEditing(_initialForm(clock.today(), categories, summary, editing, kind))) {
    on<AddEntryKindChanged>(_onKindChanged);
    on<AddEntryKeyPressed>(
      (AddEntryKeyPressed event, Emitter<AddEntryState> emit) =>
          _editAmount(emit, (int rupees) => AmountInput.append(rupees, event.key)),
    );
    on<AddEntryQuickAdded>(
      (AddEntryQuickAdded event, Emitter<AddEntryState> emit) =>
          _editAmount(emit, (int current) => AmountInput.add(current, event.rupees)),
    );
    on<AddEntryBackspacePressed>(
      (AddEntryBackspacePressed event, Emitter<AddEntryState> emit) =>
          _editAmount(emit, (int rupees) => Option<int>.of(AmountInput.backspace(rupees))),
    );
    on<AddEntryCleared>(
      (AddEntryCleared event, Emitter<AddEntryState> emit) => _editAmount(emit, (int _) => const Option<int>.of(0)),
    );
    on<AddEntryNextPressed>(_onNextPressed);
    on<AddEntryBackPressed>(_onBackPressed);
    on<AddEntryDateChanged>(_onDateChanged);
    on<AddEntryNoteChanged>(
      (AddEntryNoteChanged event, Emitter<AddEntryState> emit) => _update(emit, (EntryForm form) => form.copyWith(note: event.note)),
    );
    // why: a second tap on a tile or Delete while the first write is in flight must not save or
    // delete twice; Delete has no in-between state to guard on.
    on<AddEntryCategoryPicked>(_onCategoryPicked, transformer: droppable());
    on<AddEntryDeleteRequested>(_onDeleteRequested, transformer: droppable());
    on<AddEntryNewCategoryOpened>(
      (AddEntryNewCategoryOpened event, Emitter<AddEntryState> emit) =>
          _update(emit, (EntryForm form) => form.copyWith(step: AddEntryStep.newName)),
    );
    on<AddEntryNewCategoryNameChanged>(
      (AddEntryNewCategoryNameChanged event, Emitter<AddEntryState> emit) =>
          _update(emit, (EntryForm form) => form.copyWith(draftName: event.name)),
    );
    on<AddEntryIconStepOpened>(
      (AddEntryIconStepOpened event, Emitter<AddEntryState> emit) =>
          _update(emit, (EntryForm form) => form.copyWith(step: AddEntryStep.newIcon)),
    );
    on<AddEntryIconPicked>(_onIconPicked);
    on<AddEntryNewCategorySaved>(_onNewCategorySaved, transformer: droppable());
  }

  /// How far back dates may go when no summary is available (about two months).
  static const int fallbackHistoryDays = 62;

  final SaveEntry _saveEntry;
  final DeleteEntry _deleteEntry;
  final AddOwnCategory _addOwnCategory;
  final Haptics _haptics;
  final List<Category> _categories;

  /// Every category the tray was opened with, hidden ones too, so the name step can say what a
  /// typed name already belongs to (FR-AD-9 AC-4).
  List<Category> get categories => _categories;
  final Option<CycleSummary> _summary;

  /// Switches between *Spent* and *Got*; the amount is kept.
  void _onKindChanged(AddEntryKindChanged event, Emitter<AddEntryState> emit) {
    unawaited(_haptics.tick());
    _update(emit, (EntryForm form) => form.copyWith(kind: event.kind, tiles: _tilesFor(_categories, event.kind)));
  }

  /// Opens step 2 when there is an amount (FR-AD-4).
  void _onNextPressed(AddEntryNextPressed event, Emitter<AddEntryState> emit) {
    if (state.form.rupees > 0) {
      _update(emit, (EntryForm form) => form.copyWith(step: AddEntryStep.category));
    }
  }

  /// Goes back one step: icon → name → grid → amount; on the amount step the page closes the
  /// tray instead. What was typed is kept (FR-AD-7, FR-AD-9 AC-5).
  void _onBackPressed(AddEntryBackPressed event, Emitter<AddEntryState> emit) {
    final AddEntryStep? previous = switch (state.form.step) {
      AddEntryStep.amount => null,
      AddEntryStep.category => AddEntryStep.amount,
      AddEntryStep.newName => AddEntryStep.category,
      AddEntryStep.newIcon => AddEntryStep.newName,
    };
    if (previous != null) {
      _update(emit, (EntryForm form) => form.copyWith(step: previous));
    }
  }

  /// Sets the new category's icon and returns to the name step; the name's own icon means
  /// "follow the name" again (FR-AD-9 AC-3).
  void _onIconPicked(AddEntryIconPicked event, Emitter<AddEntryState> emit) => _update(
        emit,
        (EntryForm form) => form.copyWith(
          step: AddEntryStep.newName,
          draftIcon: event.iconKey == CategoryIcon.forName(form.draftName) ? const Option<String>.none() : Option<String>.of(event.iconKey),
        ),
      );

  /// Finds or makes the category the typed name belongs to, then saves the entry in it (FR-AD-9 AC-4).
  Future<void> _onNewCategorySaved(AddEntryNewCategorySaved event, Emitter<AddEntryState> emit) async {
    final AddEntryState current = state;
    if (current is! AddEntryEditing || current.form.draftName.trim().isEmpty) {
      return;
    }
    final EntryForm form = current.form;
    emit(AddEntrySaving(form));
    final Either<Failure, Entry> saved = await _addOwnCategory(
      NewCategory(name: form.draftName, iconKey: form.draftIconKey, labels: event.labels),
    ).flatMap((Category category) => _saveEntry(SaveEntryParams(_draftIn(form, category.id), replacing: form.editing.map((Entry e) => e.id)))).run();
    _finishOrFail(emit, saved, form);
  }

  static EntryDraft _draftIn(EntryForm form, int categoryId) =>
      EntryDraft(amount: form.amount, kind: form.kind, categoryId: categoryId, date: form.date, note: form.note);

  /// Sets the entry's date, kept between the earliest allowed day and today (BR-10).
  void _onDateChanged(AddEntryDateChanged event, Emitter<AddEntryState> emit) => _update(emit, (EntryForm form) {
        final CalendarDate notFuture = event.date.isAfter(form.today) ? form.today : event.date;
        return form.copyWith(date: notFuture.isBefore(form.earliestDate) ? form.earliestDate : notFuture);
      });

  Future<void> _onCategoryPicked(AddEntryCategoryPicked event, Emitter<AddEntryState> emit) async {
    final AddEntryState current = state;
    if (current is! AddEntryEditing) {
      return;
    }
    final EntryForm form = current.form;
    final int categoryId = event.categoryId;
    emit(AddEntrySaving(form, categoryId: categoryId));
    final Either<Failure, Entry> saved = await _saveEntry(
      SaveEntryParams(_draftIn(form, categoryId), replacing: form.editing.map((Entry entry) => entry.id)),
    ).run();
    _finishOrFail(emit, saved, form, categoryId: categoryId);
  }

  /// Deletes the entry being edited and closes the tray; does nothing when adding.
  Future<void> _onDeleteRequested(AddEntryDeleteRequested event, Emitter<AddEntryState> emit) async {
    final AddEntryState current = state;
    final Entry? editing = current.form.editing.toNullable();
    if (current is! AddEntryEditing || editing == null) {
      return;
    }
    final Either<Failure, Entry> deleted = await _deleteEntry(editing.id).run();
    _finishOrFail(emit, deleted, current.form);
  }

  void _finishOrFail(Emitter<AddEntryState> emit, Either<Failure, Entry> result, EntryForm form, {int? categoryId}) =>
      result.match(
        (Failure failure) {
          AppLogger.log(tag: 'add_entry.save_failed', data: <String, Object?>{'type': failure.runtimeType.toString()});
          unawaited(_haptics.reject());
          emit(AddEntryEditing(form, failed: true));
        },
        (Entry _) {
          unawaited(_haptics.success());
          emit(AddEntryFinished(form, categoryId: categoryId));
        },
      );

  void _editAmount(Emitter<AddEntryState> emit, Option<int> Function(int rupees) edit) {
    final AddEntryState current = state;
    if (current is! AddEntryEditing) {
      return;
    }
    edit(current.form.rupees).match(
      () {
        unawaited(_haptics.reject());
        emit(AddEntryEditing(current.form, rejections: current.rejections + 1));
      },
      (int rupees) {
        unawaited(_haptics.tick());
        _update(emit, (EntryForm form) => form.copyWith(rupees: rupees));
      },
    );
  }

  void _update(Emitter<AddEntryState> emit, EntryForm Function(EntryForm form) change) {
    final AddEntryState current = state;
    if (current is! AddEntryEditing) {
      return;
    }
    final EntryForm changed = change(current.form);
    emit(AddEntryEditing(changed.copyWith(preview: _previewFor(changed, _summary)), rejections: current.rejections));
  }

  static EntryForm _initialForm(
    CalendarDate today,
    List<Category> categories,
    Option<CycleSummary> summary,
    Option<Entry> editing,
    EntryKind kind,
  ) {
    final Entry? entry = editing.toNullable();
    final EntryKind startKind = entry?.kind ?? kind;
    final EntryForm form = EntryForm(
      kind: startKind,
      rupees: entry?.amount.floorMajor ?? 0,
      date: entry?.date ?? today,
      today: today,
      earliestDate: summary.match(
        () => today.addDays(-fallbackHistoryDays),
        (CycleSummary summary) => summary.earliestEntryDate,
      ),
      tiles: _tilesFor(categories, startKind),
      note: entry?.note ?? '',
      editing: editing,
    );
    return form.copyWith(preview: _previewFor(form, summary));
  }

  // why: a hidden category of the user's own keeps its entries but leaves the tray (D138).
  static List<Category> _tilesFor(List<Category> categories, EntryKind kind) =>
      categories.where((Category category) => category.kind == kind && !category.hidden).toList()
        ..sort((Category a, Category b) => a.sort.compareTo(b.sort));

  // why: an edited entry from today is already inside spentToday, so only the change counts. A bill
  // the app posted sits in the pool, not spentToday (D119), so "left today" doesn't describe its change.
  static Option<SpendPreview> _previewFor(EntryForm form, Option<CycleSummary> summary) {
    final bool editingABill = form.editing.filter((Entry entry) => entry.recurringId != null).isSome();
    if (form.kind != EntryKind.spent || form.rupees == 0 || form.date != form.today || editingABill) {
      return const Option<SpendPreview>.none();
    }
    final Money alreadyCounted = form.editing
        .filter((Entry entry) => entry.kind == EntryKind.spent && entry.date == form.today)
        .match(() => Money.zero, (Entry entry) => entry.amount);
    return summary.map((CycleSummary summary) => SafeToSpend.previewSpend(summary, form.amount - alreadyCounted));
  }
}
