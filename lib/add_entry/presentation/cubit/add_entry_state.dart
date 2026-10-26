import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../ledger/ledger.dart';

/// The tray's two steps (SPEC FR-AD-1, FR-AD-5).
enum AddEntryStep {
  amount,
  category,
}

/// Everything the tray has collected so far.
final class EntryForm extends Equatable {
  const EntryForm({
    required this.kind,
    required this.rupees,
    required this.date,
    required this.today,
    required this.earliestDate,
    required this.tiles,
    this.note = '',
    this.step = AddEntryStep.amount,
    this.editing = const Option<Entry>.none(),
    this.preview = const Option<SpendPreview>.none(),
  });

  final EntryKind kind;

  /// Whole rupees typed; 0 means nothing typed yet.
  final int rupees;
  final CalendarDate date;
  final CalendarDate today;

  /// The oldest date the date chip allows (BR-10).
  final CalendarDate earliestDate;

  /// The categories for [kind], in their fixed order (BR-11).
  final List<Category> tiles;
  final String note;
  final AddEntryStep step;

  /// The entry being edited (FR-AD-8); [None] when adding.
  final Option<Entry> editing;

  /// What this amount does to today, for *Spent* entries dated today (FR-AD-3).
  final Option<SpendPreview> preview;

  Money get amount => Money.fromMajor(rupees);

  /// Returns a copy with the given fields replaced.
  EntryForm copyWith({
    EntryKind? kind,
    int? rupees,
    CalendarDate? date,
    List<Category>? tiles,
    String? note,
    AddEntryStep? step,
    Option<SpendPreview>? preview,
  }) =>
      EntryForm(
        kind: kind ?? this.kind,
        rupees: rupees ?? this.rupees,
        date: date ?? this.date,
        today: today,
        earliestDate: earliestDate,
        tiles: tiles ?? this.tiles,
        note: note ?? this.note,
        step: step ?? this.step,
        editing: editing,
        preview: preview ?? this.preview,
      );

  @override
  List<Object?> get props => <Object?>[kind, rupees, date, today, earliestDate, tiles, note, step, editing, preview];
}

/// The Add tray's situation.
sealed class AddEntryState extends Equatable {
  const AddEntryState(this.form);

  final EntryForm form;

  @override
  List<Object?> get props => <Object?>[form];
}

/// Typing or choosing. [rejections] counts refused keys so the amount shakes; [failed] shows
/// "Couldn't save. Try again." with everything kept (FR-AD-6).
final class AddEntryEditing extends AddEntryState {
  const AddEntryEditing(super.form, {this.rejections = 0, this.failed = false});

  final int rejections;
  final bool failed;

  @override
  List<Object?> get props => <Object?>[form, rejections, failed];
}

/// Saving after a tile tap; that tile shows the ink flash and further taps are ignored.
final class AddEntrySaving extends AddEntryState {
  const AddEntrySaving(super.form, {required this.categoryId});

  final int categoryId;

  @override
  List<Object?> get props => <Object?>[form, categoryId];
}

/// Saved or deleted; the tray closes.
final class AddEntryFinished extends AddEntryState {
  const AddEntryFinished(super.form, {this.categoryId});

  /// The tile that saved, so it stays flashed while the tray drops; null after a delete.
  final int? categoryId;

  @override
  List<Object?> get props => <Object?>[form, categoryId];
}
