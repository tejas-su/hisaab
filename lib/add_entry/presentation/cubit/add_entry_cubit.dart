import 'dart:async';

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
import 'add_entry_state.dart';

/// Owns the Add tray (SPEC FR-AD): the amount, Spent/Got, date, note and the save on a tile tap.
///
/// Created per tray opening by the route, with the Home summary for the preview line and the
/// entry being edited, if any. The page closes the tray on [AddEntryFinished].
class AddEntryCubit extends Cubit<AddEntryState> {
  AddEntryCubit({
    required this._saveEntry,
    required this._deleteEntry,
    required this._haptics,
    required Clock clock,
    required List<Category> categories,
    Option<CycleSummary> summary = const Option<CycleSummary>.none(),
    Option<Entry> editing = const Option<Entry>.none(),
    EntryKind kind = EntryKind.spent,
  })  : _categories = categories,
        _summary = summary,
        super(AddEntryEditing(_initialForm(clock.today(), categories, summary, editing, kind)));

  /// How far back dates may go when no summary is available (about two months).
  static const int fallbackHistoryDays = 62;

  final SaveEntry _saveEntry;
  final DeleteEntry _deleteEntry;
  final Haptics _haptics;
  final List<Category> _categories;
  final Option<CycleSummary> _summary;

  /// Switches between *Spent* and *Got*; the amount is kept.
  void setKind(EntryKind kind) {
    unawaited(_haptics.tick());
    _update((EntryForm form) => form.copyWith(kind: kind, tiles: _tilesFor(_categories, kind)));
  }

  /// Types [key] (`0`–`9`, `00`); a 10th digit is refused (FR-AD-2).
  void pressKey(String key) => _editAmount((int rupees) => AmountInput.append(rupees, key));

  /// Adds a quick-chip amount (FR-AD-1).
  void quickAdd(int rupees) => _editAmount((int current) => AmountInput.add(current, rupees));

  /// Removes the last digit.
  void backspace() => _editAmount((int rupees) => Option<int>.of(AmountInput.backspace(rupees)));

  /// Empties the amount (long-press ⌫).
  void clear() => _editAmount((int _) => const Option<int>.of(0));

  /// Opens step 2 when there is an amount (FR-AD-4).
  void next() {
    if (state.form.rupees > 0) {
      _update((EntryForm form) => form.copyWith(step: AddEntryStep.category));
    }
  }

  /// Goes back from step 2 to step 1; returns false on step 1, where back closes the tray.
  bool back() {
    if (state.form.step == AddEntryStep.amount) {
      return false;
    }
    _update((EntryForm form) => form.copyWith(step: AddEntryStep.amount));
    return true;
  }

  /// Sets the entry's date, kept between the earliest allowed day and today (BR-10).
  void setDate(CalendarDate date) => _update((EntryForm form) {
        final CalendarDate notFuture = date.isAfter(form.today) ? form.today : date;
        return form.copyWith(date: notFuture.isBefore(form.earliestDate) ? form.earliestDate : notFuture);
      });

  /// Sets the note text; it is trimmed when saved.
  void setNote(String note) => _update((EntryForm form) => form.copyWith(note: note));

  /// Saves with category [categoryId]: the tile tap is the save (FR-AD-5). Ignored while saving.
  Future<void> pickCategory(int categoryId) async {
    final AddEntryState current = state;
    if (current is! AddEntryEditing) {
      return;
    }
    final EntryForm form = current.form;
    emit(AddEntrySaving(form, categoryId: categoryId));
    final EntryDraft draft = EntryDraft(
      amount: form.amount,
      kind: form.kind,
      categoryId: categoryId,
      date: form.date,
      note: form.note,
    );
    final Either<Failure, Entry> saved = await _saveEntry(
      SaveEntryParams(draft, replacing: form.editing.map((Entry entry) => entry.id)),
    ).run();
    if (isClosed) {
      return;
    }
    _finishOrFail(saved, form, categoryId: categoryId);
  }

  /// Deletes the entry being edited and closes the tray; does nothing when adding.
  Future<void> delete() async {
    final AddEntryState current = state;
    final Entry? editing = current.form.editing.toNullable();
    if (current is! AddEntryEditing || editing == null) {
      return;
    }
    final Either<Failure, Entry> deleted = await _deleteEntry(editing.id).run();
    if (isClosed) {
      return;
    }
    _finishOrFail(deleted, current.form);
  }

  void _finishOrFail(Either<Failure, Entry> result, EntryForm form, {int? categoryId}) => result.match(
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

  void _editAmount(Option<int> Function(int rupees) edit) {
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
        _update((EntryForm form) => form.copyWith(rupees: rupees));
      },
    );
  }

  void _update(EntryForm Function(EntryForm form) change) {
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

  static List<Category> _tilesFor(List<Category> categories, EntryKind kind) =>
      categories.where((Category category) => category.kind == kind).toList()
        ..sort((Category a, Category b) => a.sort.compareTo(b.sort));

  // why: an edited entry from today is already inside spentToday, so only the change counts.
  static Option<SpendPreview> _previewFor(EntryForm form, Option<CycleSummary> summary) {
    if (form.kind != EntryKind.spent || form.rupees == 0 || form.date != form.today) {
      return const Option<SpendPreview>.none();
    }
    final Money alreadyCounted = form.editing
        .filter((Entry entry) => entry.kind == EntryKind.spent && entry.date == form.today)
        .match(() => Money.zero, (Entry entry) => entry.amount);
    return summary.map((CycleSummary summary) => SafeToSpend.previewSpend(summary, form.amount - alreadyCounted));
  }
}
