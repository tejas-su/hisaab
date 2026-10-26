import 'package:fpdart/fpdart.dart';

import '../../core/errors/failure.dart';
import '../../core/money/amount_input.dart';
import '../../core/money/money.dart';
import '../../core/time/calendar_date.dart';
import 'entities/entry_draft.dart';
import 'failures/ledger_failures.dart';

/// Checks an entry against SPEC BR-10 before it is saved.
abstract final class EntryValidator {
  /// The longest note allowed, after trimming.
  static const int maxNoteLength = 80;

  /// Validates [draft] for [today]: the amount is ₹1 to ₹99,99,99,999, the date isn't in the
  /// future and the trimmed note fits; a blank note becomes null.
  ///
  /// Returns [Right] with the cleaned draft, or [Left] with [InvalidAmountFailure],
  /// [FutureDateFailure] or [NoteTooLongFailure].
  static Either<Failure, EntryDraft> validate(EntryDraft draft, {required CalendarDate today}) {
    final int minorPerMajor = draft.amount.currency.minorPerMajor;
    final Money max = Money(AmountInput.maxRupees * minorPerMajor, currency: draft.amount.currency);
    if (draft.amount.amountMinor < minorPerMajor || draft.amount > max) {
      return Either<Failure, EntryDraft>.left(InvalidAmountFailure('Amount out of range: ${draft.amount.amountMinor}'));
    }
    if (draft.date.isAfter(today)) {
      return Either<Failure, EntryDraft>.left(FutureDateFailure('Entry dated ${draft.date} after $today'));
    }
    return _cleanNote(draft);
  }

  static Either<Failure, EntryDraft> _cleanNote(EntryDraft draft) {
    final String trimmed = (draft.note ?? '').trim();
    if (trimmed.length > maxNoteLength) {
      return Either<Failure, EntryDraft>.left(NoteTooLongFailure('Note has ${trimmed.length} characters'));
    }
    return Either<Failure, EntryDraft>.right(draft.withNote(trimmed.isEmpty ? null : trimmed));
  }
}
