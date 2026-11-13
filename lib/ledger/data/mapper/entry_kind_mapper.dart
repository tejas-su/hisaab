import 'package:fpdart/fpdart.dart';

import '../../../core/db/db_schema.dart';
import '../../../core/errors/failure.dart';
import '../../domain/entities/entry_kind.dart';

/// Converts [EntryKind] to and from the stored `kind` column (`out` / `in` / `save` / `card` / `used`).
abstract final class EntryKindMapper {
  /// The stored value of [kind].
  static String toValue(EntryKind kind) => switch (kind) {
        EntryKind.spent => EntryKindValues.spent,
        EntryKind.got => EntryKindValues.got,
        EntryKind.saved => EntryKindValues.saved,
        EntryKind.cardPaid => EntryKindValues.cardPaid,
        EntryKind.used => EntryKindValues.used,
      };

  /// Returns [Right] with the kind, or [Left] with [InvalidDataFailure] for an unknown [value].
  static Either<Failure, EntryKind> fromValue(String value) => switch (value) {
        EntryKindValues.spent => Either<Failure, EntryKind>.right(EntryKind.spent),
        EntryKindValues.got => Either<Failure, EntryKind>.right(EntryKind.got),
        EntryKindValues.saved => Either<Failure, EntryKind>.right(EntryKind.saved),
        EntryKindValues.cardPaid => Either<Failure, EntryKind>.right(EntryKind.cardPaid),
        EntryKindValues.used => Either<Failure, EntryKind>.right(EntryKind.used),
        _ => Either<Failure, EntryKind>.left(InvalidDataFailure('Unknown kind "$value"')),
      };
}
