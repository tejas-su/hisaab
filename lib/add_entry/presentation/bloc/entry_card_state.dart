import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../../ledger/ledger.dart';

/// The part of the entry card that is unfolded (SPEC FR-AD-8 AC-2).
enum CardPart {
  /// The keypad under the amount (AC-3).
  amount,

  /// The category grid (AC-4).
  category,

  /// The naming step that takes the grid's place after *New* (AC-5).
  naming,

  /// The day pills (AC-6).
  day,
}

/// One kind of change the card can make; the Undo bar names them (SPEC BR-10).
enum CardChange { amount, category, day, note }

/// What the entry card is showing: the entry as it was, and the values as they are now.
///
/// [rupees], [categoryId], [date] and [note] are what closing would write. [typed] is an amount
/// being typed on the keypad and not yet kept; [None] while the old amount is shown picked, so the
/// first digit replaces it (AC-3).
final class EntryCardForm extends Equatable {
  const EntryCardForm({
    required this.original,
    required this.rupees,
    required this.categoryId,
    required this.date,
    required this.note,
    required this.today,
    required this.earliestDate,
    required this.categories,
    this.part = const Option<CardPart>.none(),
    this.typed = const Option<int>.none(),
    this.draftName = '',
    this.draftIcon = const Option<String>.none(),
    this.safeToday = const Option<Money>.none(),
  });

  /// The entry as it was when the card opened; Undo writes it back.
  final Entry original;
  final int rupees;
  final int categoryId;
  final CalendarDate date;
  final String note;
  final CalendarDate today;

  /// The first day the entry may move to (BR-10).
  final CalendarDate earliestDate;

  /// Every category, hidden ones too, so a typed name can find the one it belongs to.
  final List<Category> categories;
  final Option<CardPart> part;
  final Option<int> typed;

  /// The new category's name and its icon while naming (AC-5); [None] follows the name.
  final String draftName;
  final Option<String> draftIcon;

  /// Home's *Safe to spend today* as the card opened, for the preview (AC-11); [None] without one.
  final Option<Money> safeToday;

  /// The amount shown: what is being typed, else the kept amount.
  int get shownRupees => typed.getOrElse(() => rupees);

  /// The new category's icon: the one picked, or the one its name suggests.
  String get draftIconKey => draftIcon.getOrElse(() => CategoryIcon.forName(draftName));

  /// The tiles of the entry's kind in order: shown categories, plus a hidden one of the user's own
  /// only while it holds this entry (AC-4).
  List<Category> get tiles => categories
      .where((Category c) => c.kind == original.kind && (!c.hidden || c.id == original.categoryId))
      .toList()
    ..sort((Category a, Category b) => a.sort.compareTo(b.sort));

  /// Whether *New* fits: the user's own shown are under the limit, on *Spent* only (FR-AD-9 AC-1).
  bool get canAddOwn =>
      original.kind == EntryKind.spent &&
      categories.where((Category c) => c.isOwn && !c.hidden && c.kind == EntryKind.spent).length < OwnCategories.max;

  /// What closing would write, the typed amount included when above ₹0 (AC-8).
  EntryDraft get draft => EntryDraft(
        amount: Money.fromMajor(typed.filter((int r) => r > 0).getOrElse(() => rupees)),
        kind: original.kind,
        categoryId: categoryId,
        date: date,
        note: note.trim().isEmpty ? null : note.trim(),
      );

  /// What differs from [original], in the order the Undo bar names them.
  List<CardChange> get changes {
    final EntryDraft now = draft;
    return <CardChange>[
      if (now.amount != original.amount) CardChange.amount,
      if (now.categoryId != original.categoryId) CardChange.category,
      if (now.date != original.date) CardChange.day,
      if ((now.note ?? '') != (original.note ?? '')) CardChange.note,
    ];
  }

  /// Home's figure if the card closed now, when the change can be shown before it is written:
  /// a typed *Spent* entry that stays dated today (AC-11). [None] when nothing would move it, or
  /// when the change reaches the pool too (a bill, a back-dated day, money in).
  Option<Money> get preview {
    final bool previewable = original.kind == EntryKind.spent &&
        original.recurringId == null &&
        original.date == today &&
        date == today;
    if (!previewable) {
      return const Option<Money>.none();
    }
    final Money delta = draft.amount - original.amount;
    return delta == Money.zero ? const Option<Money>.none() : safeToday.map((Money safe) => safe - delta);
  }

  /// Returns a copy with the given fields replaced.
  EntryCardForm copyWith({
    int? rupees,
    int? categoryId,
    CalendarDate? date,
    String? note,
    List<Category>? categories,
    Option<CardPart>? part,
    Option<int>? typed,
    String? draftName,
    Option<String>? draftIcon,
  }) =>
      EntryCardForm(
        original: original,
        rupees: rupees ?? this.rupees,
        categoryId: categoryId ?? this.categoryId,
        date: date ?? this.date,
        note: note ?? this.note,
        today: today,
        earliestDate: earliestDate,
        categories: categories ?? this.categories,
        part: part ?? this.part,
        typed: typed ?? this.typed,
        draftName: draftName ?? this.draftName,
        draftIcon: draftIcon ?? this.draftIcon,
        safeToday: safeToday,
      );

  @override
  List<Object?> get props =>
      <Object?>[original, rupees, categoryId, date, note, today, earliestDate, categories, part, typed, draftName, draftIcon, safeToday];
}

/// A change written when the card closed: Undo writes [original] back (SPEC BR-10). [categories]
/// are the card's, a category made in it included, so the Undo bar can name the one moved to;
/// [today] lets it say "today" or "yesterday".
final class EntryEdit extends Equatable {
  const EntryEdit({required this.original, required this.saved, required this.changes, required this.categories, required this.today});

  final Entry original;
  final Entry saved;
  final List<CardChange> changes;
  final List<Category> categories;
  final CalendarDate today;

  @override
  List<Object?> get props => <Object?>[original, saved, changes, categories, today];
}

/// The entry card's state (SPEC FR-AD-8).
sealed class EntryCardState extends Equatable {
  const EntryCardState();

  @override
  List<Object?> get props => <Object?>[];
}

/// No card is open. [edit] is the change just written, offered once for Undo; [deleted] is an
/// entry whose Delete was tapped, for the page to delete with its own Undo (AC-10).
final class EntryCardClosed extends EntryCardState {
  const EntryCardClosed({this.edit = const Option<EntryEdit>.none(), this.deleted = const Option<Entry>.none()});

  final Option<EntryEdit> edit;
  final Option<Entry> deleted;

  @override
  List<Object?> get props => <Object?>[edit, deleted];
}

/// A card is open on [form]. [rejections] counts refused keys, for the shake and ring (FR-AD-2);
/// [failed] says the last write did not land (AC-9).
final class EntryCardOpen extends EntryCardState {
  const EntryCardOpen(this.form, {this.rejections = 0, this.failed = false});

  final EntryCardForm form;
  final int rejections;
  final bool failed;

  @override
  List<Object?> get props => <Object?>[form, rejections, failed];
}

/// The card is writing; taps are ignored until it closes or fails.
final class EntryCardSaving extends EntryCardState {
  const EntryCardSaving(this.form);

  final EntryCardForm form;

  @override
  List<Object?> get props => <Object?>[form];
}
