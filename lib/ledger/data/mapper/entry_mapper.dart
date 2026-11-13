import 'package:fpdart/fpdart.dart';

import '../../../core/errors/failure.dart';
import '../../../core/money/currency_spec.dart';
import '../../../core/money/money.dart';
import '../../../core/time/calendar_date.dart';
import '../../domain/entities/entry.dart';
import '../../domain/entities/entry_draft.dart';
import '../../domain/entities/entry_kind.dart';
import '../model/entry_model.dart';
import 'entry_kind_mapper.dart';

/// Converts between [EntryModel] rows and [Entry] entities.
abstract final class EntryMapper {
  /// Returns [Right] with the entry, or [Left] with `InvalidDataFailure` for an unknown kind or
  /// currency, a bad date or created time, or a row without an id.
  static Either<Failure, Entry> toEntity(EntryModel model) => CurrencySpec.fromCode(model.currency).flatMap(
        (CurrencySpec currency) => EntryKindMapper.fromValue(model.kind).flatMap(
          (EntryKind entryKind) => CalendarDate.parse(model.date).flatMap(
            (CalendarDate date) => _createdAt(model.createdAt).flatMap(
              (DateTime createdAt) => Option<int>.fromNullable(model.id)
                  .toEither<Failure>(() => const InvalidDataFailure('Entry row without an id'))
                  .map(
                    (int id) => Entry(
                      id: id,
                      amount: Money(model.amountMinor, currency: currency),
                      kind: entryKind,
                      categoryId: model.categoryId,
                      date: date,
                      createdAt: createdAt,
                      note: model.note,
                      recurringId: model.recurringId,
                      savingId: model.savingId,
                    ),
                  ),
            ),
          ),
        ),
      );

  static Either<Failure, DateTime> _createdAt(String text) => Option<DateTime>.fromNullable(DateTime.tryParse(text))
      .toEither<Failure>(() => InvalidDataFailure('Bad created_at "$text"'));

  /// The row for [draft], with an optional [id], [recurringId] and [savingId], stamped [createdAt].
  static EntryModel toModel(
    EntryDraft draft, {
    required DateTime createdAt,
    int? id,
    int? recurringId,
    int? savingId,
  }) =>
      EntryModel(
        id: id,
        amountMinor: draft.amount.amountMinor,
        currency: draft.amount.currency.code,
        kind: EntryKindMapper.toValue(draft.kind),
        categoryId: draft.categoryId,
        date: draft.date.toIso(),
        note: draft.note,
        recurringId: recurringId,
        savingId: savingId,
        createdAt: createdAt.toIso8601String(),
      );
}
