import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import 'entry_kind.dart';

/// An entry the user is about to save: what the Add tray collects before it has an id.
final class EntryDraft extends Equatable {
  const EntryDraft({
    required this.amount,
    required this.kind,
    required this.categoryId,
    required this.date,
    this.note,
  });

  final Money amount;
  final EntryKind kind;
  final int categoryId;

  /// The day the money moved; never after today (SPEC BR-10).
  final CalendarDate date;

  /// Optional free text, at most 80 characters after trimming (SPEC BR-10).
  final String? note;

  /// Returns a copy with [note] replaced, so validation can store the trimmed text.
  EntryDraft withNote(String? note) =>
      EntryDraft(amount: amount, kind: kind, categoryId: categoryId, date: date, note: note);

  @override
  List<Object?> get props => <Object?>[amount, kind, categoryId, date, note];
}
