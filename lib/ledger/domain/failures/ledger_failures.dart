import '../../../core/errors/failure.dart';

/// An amount of ₹0, a negative amount or more than 9 digits (SPEC BR-10).
final class InvalidAmountFailure extends Failure {
  const InvalidAmountFailure(super.message);
}

/// An entry dated after today (SPEC BR-10).
final class FutureDateFailure extends Failure {
  const FutureDateFailure(super.message);
}

/// A note longer than 80 characters after trimming (SPEC BR-10).
final class NoteTooLongFailure extends Failure {
  const NoteTooLongFailure(super.message);
}

/// An edit, delete or restore named an entry id that doesn't exist (or already exists, for restore).
final class EntryNotFoundFailure extends Failure {
  const EntryNotFoundFailure(super.message);
}
