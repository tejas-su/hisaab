import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../habits/habits.dart';
import '../../../ledger/ledger.dart';

/// The tray's steps (SPEC FR-AD-1, FR-AD-5, FR-AD-9).
enum AddEntryStep {
  amount,
  category,

  /// Naming a new category of the user's own, from the *New* tile.
  newName,

  /// Picking that new category's icon.
  newIcon,
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
    this.draftName = '',
    this.draftIcon = const Option<String>.none(),
    this.usual = const Option<UsualSpend>.none(),
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

  /// The name typed for a new category (FR-AD-9); kept until the tray closes.
  final String draftName;

  /// The icon key the user picked for the new category; [None] follows the name.
  final Option<String> draftIcon;

  /// The *your usual* pill to offer (FR-AD-10): [Some] only from the tray's first frame until
  /// the first input, [None] in every other case.
  final Option<UsualSpend> usual;

  Money get amount => Money.fromMajor(rupees);

  /// The new category's icon: the one picked, or the one its name suggests (D138).
  String get draftIconKey => draftIcon.getOrElse(() => CategoryIcon.forName(draftName));

  /// Whether the *New* tile shows: *Spent*, with fewer than 4 of the user's own (D138).
  bool get canAddOwn => kind == EntryKind.spent && tiles.where((Category c) => c.isOwn).length < OwnCategories.max;

  /// Returns a copy with the given fields replaced.
  EntryForm copyWith({
    EntryKind? kind,
    int? rupees,
    CalendarDate? date,
    List<Category>? tiles,
    String? note,
    AddEntryStep? step,
    Option<SpendPreview>? preview,
    String? draftName,
    Option<String>? draftIcon,
    Option<UsualSpend>? usual,
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
        draftName: draftName ?? this.draftName,
        draftIcon: draftIcon ?? this.draftIcon,
        usual: usual ?? this.usual,
      );

  @override
  List<Object?> get props =>
      <Object?>[kind, rupees, date, today, earliestDate, tiles, note, step, editing, preview, draftName, draftIcon, usual];
}

/// The Add tray's situation.
sealed class AddEntryState extends Equatable {
  const AddEntryState(this.form);

  final EntryForm form;
}

/// Typing or choosing. [rejections] counts refused keys so the amount shakes; [failed] shows
/// "Couldn't save. Try again." with everything kept (FR-AD-6), in the pill after a pill tap
/// (FR-AD-10 AC-4).
final class AddEntryEditing extends AddEntryState {
  const AddEntryEditing(super.form, {this.rejections = 0, this.failed = false});

  final int rejections;
  final bool failed;

  @override
  List<Object?> get props => <Object?>[form, rejections, failed];
}

/// Saving after a tile or pill tap; that tile or the pill shows the ink flash and further taps
/// are ignored.
final class AddEntrySaving extends AddEntryState {
  const AddEntrySaving(super.form, {this.categoryId});

  /// The tile that was tapped, or the pill's category; null while a new category is being made
  /// (FR-AD-9).
  final int? categoryId;

  @override
  List<Object?> get props => <Object?>[form, categoryId];
}

/// Saved or deleted; the tray closes.
final class AddEntryFinished extends AddEntryState {
  const AddEntryFinished(super.form, {this.categoryId, this.added = const Option<Entry>.none()});

  /// The tile that saved, so it stays flashed while the tray drops; null after a delete.
  final int? categoryId;

  /// The entry one tap on the *your usual* pill saved, which the app offers to undo (BR-10);
  /// [None] after every other save and after a delete.
  final Option<Entry> added;

  // why: the entry is listed only when there is one, so a save without a pill compares exactly
  // as it did before the pill existed.
  @override
  List<Object?> get props => <Object?>[form, categoryId, ...added.match(() => const <Entry>[], (Entry entry) => <Entry>[entry])];
}
