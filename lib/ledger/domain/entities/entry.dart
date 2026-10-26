import 'package:equatable/equatable.dart';

import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import 'entry_draft.dart';
import 'entry_kind.dart';

/// One saved money movement, typed by the user or posted by a recurring rule (SPEC §2).
final class Entry extends Equatable {
  const Entry({
    required this.id,
    required this.amount,
    required this.kind,
    required this.categoryId,
    required this.date,
    required this.createdAt,
    this.note,
    this.recurringId,
  });

  final int id;
  final Money amount;
  final EntryKind kind;
  final int categoryId;
  final CalendarDate date;

  /// When the entry was first saved; edits and Undo keep it, so it records real habits.
  final DateTime createdAt;
  final String? note;

  /// The rule that posted this entry; null for entries the user typed.
  final int? recurringId;

  /// The editable part of this entry, used to prefill the Add tray (SPEC FR-AD-8).
  EntryDraft get draft => EntryDraft(amount: amount, kind: kind, categoryId: categoryId, date: date, note: note);

  @override
  List<Object?> get props => <Object?>[id, amount, kind, categoryId, date, createdAt, note, recurringId];
}
