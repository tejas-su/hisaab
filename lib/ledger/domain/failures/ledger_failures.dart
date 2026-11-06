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

/// An edit, delete or restore named a recurring rule that doesn't exist or is no longer active.
final class RuleNotFoundFailure extends Failure {
  const RuleNotFoundFailure(super.message);
}

/// A bill name that is blank or longer than `BillValidator.maxLabelLength` after trimming.
final class InvalidBillNameFailure extends Failure {
  const InvalidBillNameFailure(super.message);
}

/// A *Put in extra* larger than what is left for the cycle (D120); saving must never make it over.
final class PutInTooMuchFailure extends Failure {
  const PutInTooMuchFailure() : super('More than is left this cycle');
}

/// A category name that is blank, longer than `OwnCategories.maxNameLength` after trimming, or
/// the export name of a hidden system category (SPEC BR-11).
final class InvalidCategoryNameFailure extends Failure {
  const InvalidCategoryNameFailure(super.message);
}

/// A rename to a name another category of the same kind already has, shown or hidden (BR-11).
final class CategoryNameTakenFailure extends Failure {
  const CategoryNameTakenFailure(super.message);
}

/// Adding or bringing back a category of the user's own when `OwnCategories.max` are shown (D138).
final class OwnCategoryLimitFailure extends Failure {
  const OwnCategoryLimitFailure() : super('4 of your own is the most');
}
